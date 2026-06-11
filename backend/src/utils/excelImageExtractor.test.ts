import JSZip from "jszip";

import { extractInCellImages } from "./excelImageExtractor.js";

/** Builds a minimal xlsx zip with one in-cell image in B2 (Excel "Place in Cell"). */
async function buildWorkbookWithInCellImage(imageBytes: Buffer): Promise<Buffer> {
  const zip = new JSZip();
  zip.file(
    "xl/worksheets/sheet1.xml",
    `<worksheet><sheetData>
      <row r="1"><c r="A1" t="s"><v>0</v></c></row>
      <row r="2"><c r="B2" t="e" vm="1"><v>#VALUE!</v></c></row>
    </sheetData></worksheet>`
  );
  zip.file(
    "xl/metadata.xml",
    `<metadata xmlns:xlrd="http://schemas.microsoft.com/office/spreadsheetml/2017/richdata">
      <futureMetadata name="XLRICHVALUE" count="1"><bk><extLst><ext><xlrd:rvb i="0"/></ext></extLst></bk></futureMetadata>
      <valueMetadata count="1"><bk><rc t="1" v="0"/></bk></valueMetadata>
    </metadata>`
  );
  zip.file(
    "xl/richData/rdrichvaluestructure.xml",
    `<rvStructures count="1"><s t="_localImage"><k n="_rvRel:LocalImageIdentifier" t="i"/><k n="CalcOrigin" t="i"/></s></rvStructures>`
  );
  zip.file(
    "xl/richData/rdrichvalue.xml",
    `<rvData count="1"><rv s="0"><v>0</v><v>5</v></rv></rvData>`
  );
  zip.file(
    "xl/richData/richValueRel.xml",
    `<richValueRels xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><rel r:id="rId1"/></richValueRels>`
  );
  zip.file(
    "xl/richData/_rels/richValueRel.xml.rels",
    `<Relationships><Relationship Id="rId1" Type="image" Target="../media/image1.png"/></Relationships>`
  );
  zip.file("xl/media/image1.png", imageBytes);
  return Buffer.from(await zip.generateAsync({ type: "uint8array" }));
}

describe("extractInCellImages", () => {
  it("maps an in-cell image to its cell reference", async () => {
    const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 1, 2, 3, 4]);
    const workbook = await buildWorkbookWithInCellImage(png);

    const images = await extractInCellImages(workbook);

    expect(images.size).toBe(1);
    const image = images.get("B2");
    expect(image).toBeDefined();
    expect(image!.extension).toBe("png");
    expect(Buffer.compare(image!.buffer, png)).toBe(0);
  });

  it("returns an empty map for a workbook without rich-data images", async () => {
    const zip = new JSZip();
    zip.file("xl/worksheets/sheet1.xml", "<worksheet><sheetData/></sheetData></worksheet>");
    const buffer = Buffer.from(await zip.generateAsync({ type: "uint8array" }));

    expect((await extractInCellImages(buffer)).size).toBe(0);
  });

  it("returns an empty map for a non-zip buffer instead of throwing", async () => {
    expect((await extractInCellImages(Buffer.from("not a zip"))).size).toBe(0);
  });
});
