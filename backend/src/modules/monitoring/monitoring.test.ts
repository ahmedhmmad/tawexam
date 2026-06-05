import { MonitoringService } from "./monitoring.service.js";

describe("MonitoringService", () => {
  it("creates a service instance", () => {
    const service = new MonitoringService();
    expect(service).toBeInstanceOf(MonitoringService);
  });
});

