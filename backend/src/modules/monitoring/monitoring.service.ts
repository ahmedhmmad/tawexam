import type { Namespace, Socket } from "socket.io";

import { verifyAccessToken } from "../../config/jwt.js";
import { getMonitoringNamespace } from "../../config/socket.js";
import { MonitoringRepository } from "./monitoring.repository.js";
import type { MonitoringEvents } from "./monitoring.types.js";

export class MonitoringService {
  constructor(private readonly repository: MonitoringRepository = new MonitoringRepository()) {}

  listActiveSessions() {
    return this.repository.listActiveSessions();
  }

  emitEvent<T extends keyof MonitoringEvents>(event: T, payload: MonitoringEvents[T]): void {
    getMonitoringNamespace().emit(event, payload);
  }

  getNamespace(): Namespace {
    return getMonitoringNamespace();
  }

  handleConnection(socket: Socket): void {
    const token = socket.handshake.auth?.token as string | undefined
      ?? socket.handshake.headers?.authorization?.replace("Bearer ", "");

    if (!token) {
      socket.emit("error", { message: "Authentication required" });
      socket.disconnect(true);
      return;
    }

    try {
      const payload = verifyAccessToken(token);
      if (payload.subjectType !== "admin") {
        socket.emit("error", { message: "Admin access required" });
        socket.disconnect(true);
        return;
      }
      socket.data.user = payload;
      socket.emit("monitoring:ready", { connected: true });
    } catch {
      socket.emit("error", { message: "Invalid token" });
      socket.disconnect(true);
    }
  }
}

