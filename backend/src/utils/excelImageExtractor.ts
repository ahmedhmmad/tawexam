import JSZip from "jszip";

/**
 * Extracts Excel "in-cell" images (the modern "Place in Cell" picture
 * feature) from an .xlsx buffer and maps them to their cell references.
 *
 * These images are NOT classic floating drawings: they are rich values
 * stored under xl/richData/, which spreadsheet libraries like `xlsx` cannot
 * read (the cell parses as an empty/#VALUE! error cell). The lookup chain is:
 *
 *   cell vm="N"  →  xl/metadata.xml valueMetadata[N-1] → futureMetadata rvb i
 *   → xl/richData/rdrichvalue.xml rv[i] (field _rvRel:LocalImageIdentifier)
 *   → xl/richData/richValueRel.xml rel[index] → r:id
 *   → xl/richData/_rels/richValueRel.xml.rels → ../media/imageX.ext
 */

export interface CellImage {
  buffer: Buffer;
  /** lowercase extension without dot, e.g. "jpeg", "png" */
  extension: string;
}

/** Cell reference (e.g. "A2") → image. Empty map when the file has none. */
export async function extractInCellImages(fileBuffer: Buffer): Promise<Map<string, CellImage>> {
  const images = new Map<string, CellImage>();

  const zip = await JSZip.loadAsync(fileBuffer).catch(() => null);
  if (!zip) return images;

  const metadataXml = await readEntry(zip, "xl/metadata.xml");
  const richValueXml = await readEntry(zip, "xl/richData/rdrichvalue.xml");
  const structureXml = await readEntry(zip, "xl/richData/rdrichvaluestructure.xml");
  const relIndexXml = await readEntry(zip, "xl/richData/richValueRel.xml");
  const relsXml = await readEntry(zip, "xl/richData/_rels/richValueRel.xml.rels");
  if (!metadataXml || !richValueXml || !structureXml || !relIndexXml || !relsXml) {
    return images; // no in-cell images in this workbook
  }

  // vm index (1-based) → futureMetadata rich value index
  const valueMetadataToRv = parseValueMetadata(metadataXml);
  // rich value index → relationship index (only for _localImage values)
  const rvToRelIndex = parseRichValues(richValueXml, structureXml);
  // relationship slot order → r:id
  const relIds = [...relIndexXml.matchAll(/<rel\s+r:id="([^"]+)"/g)].map((m) => m[1]);
  // r:id → media path
  const relTargets = new Map(
    [...relsXml.matchAll(/<Relationship[^>]*Id="([^"]+)"[^>]*Target="([^"]+)"/g)].map((m) => [
      m[1],
      m[2].replace("../", "xl/")
    ])
  );

  // Walk every worksheet for cells carrying value metadata (vm="N")
  const sheetNames = Object.keys(zip.files).filter((name) =>
    /^xl\/worksheets\/sheet\d+\.xml$/.test(name)
  );

  for (const sheetName of sheetNames) {
    const sheetXml = await readEntry(zip, sheetName);
    if (!sheetXml) continue;

    for (const match of sheetXml.matchAll(/<c\s+[^>]*?r="([A-Z]+\d+)"[^>]*?vm="(\d+)"[^>]*?>/g)) {
      const cellRef = match[1];
      const vm = Number(match[2]);
      const rvIndex = valueMetadataToRv[vm - 1];
      if (rvIndex === undefined) continue;
      const relIndex = rvToRelIndex.get(rvIndex);
      if (relIndex === undefined) continue;
      const relId = relIds[relIndex];
      const mediaPath = relId ? relTargets.get(relId) : undefined;
      if (!mediaPath) continue;

      const media = zip.file(mediaPath);
      if (!media) continue;
      const buffer = Buffer.from(await media.async("uint8array"));
      const extension = (mediaPath.split(".").pop() ?? "").toLowerCase();
      images.set(cellRef, { buffer, extension });
    }
  }

  return images;
}

async function readEntry(zip: JSZip, path: string): Promise<string | null> {
  const entry = zip.file(path);
  if (!entry) return null;
  return entry.async("text");
}

/** valueMetadata bk order → futureMetadata rvb index (the rich value index). */
function parseValueMetadata(metadataXml: string): number[] {
  // futureMetadata blocks carry <xlrd:rvb i="K"/> in order
  const futureSection = metadataXml.match(/<futureMetadata[^>]*name="XLRICHVALUE"[\s\S]*?<\/futureMetadata>/)?.[0] ?? "";
  const rvbIndexes = [...futureSection.matchAll(/<xlrd:rvb\s+i="(\d+)"/g)].map((m) => Number(m[1]));

  // valueMetadata blocks carry <rc t="1" v="J"/> in order, J pointing into futureMetadata
  const valueSection = metadataXml.match(/<valueMetadata[\s\S]*?<\/valueMetadata>/)?.[0] ?? "";
  return [...valueSection.matchAll(/<rc\s+[^>]*?v="(\d+)"/g)].map((m) => {
    const futureIndex = Number(m[1]);
    return rvbIndexes[futureIndex] ?? futureIndex;
  });
}

/** rich value index → relationship slot index, for _localImage structures only. */
function parseRichValues(richValueXml: string, structureXml: string): Map<number, number> {
  // Which structures are local images, and at which field position the
  // relationship identifier sits
  const structures = [...structureXml.matchAll(/<s\s+t="([^"]+)">([\s\S]*?)<\/s>/g)].map((m) => {
    const keys = [...m[2].matchAll(/<k\s+n="([^"]+)"/g)].map((k) => k[1]);
    return { type: m[1], relFieldIndex: keys.indexOf("_rvRel:LocalImageIdentifier") };
  });

  const result = new Map<number, number>();
  const rvMatches = [...richValueXml.matchAll(/<rv\s+s="(\d+)">([\s\S]*?)<\/rv>/g)];
  rvMatches.forEach((m, rvIndex) => {
    const structure = structures[Number(m[1])];
    if (!structure || structure.type !== "_localImage" || structure.relFieldIndex < 0) return;
    const values = [...m[2].matchAll(/<v>([^<]*)<\/v>/g)].map((v) => v[1]);
    const relIndex = Number(values[structure.relFieldIndex]);
    if (!Number.isNaN(relIndex)) result.set(rvIndex, relIndex);
  });
  return result;
}
