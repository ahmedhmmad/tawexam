export interface StudentFilters {
  page: number;
  limit: number;
  search?: string;
  branch?: string;
  isActive?: boolean;
}

export interface StudentImportRow {
  id: string;
  name: string;
  mobile_no: string;
}
