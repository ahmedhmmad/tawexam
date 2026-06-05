export interface StudentFilters {
  page: number;
  limit: number;
  search?: string;
  branch?: string;
  isActive?: boolean;
}

export interface StudentImportRow {
  seatNumber: string;
  fullName: string;
  password: string;
  branch: string;
  schoolName: string;
  isActive?: boolean;
}

