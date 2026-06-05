import type { Namespace, Socket } from "socket.io";

import { getMonitoringNamespace } from "../../config/socket.js";
import type { MonitoringEvents } from "./monitoring.types.js";

export class MonitoringService {
  emitEvent<T extends keyof MonitoringEvents>(event: T, payload: MonitoringEvents[T]): void {
    getMonitoringNamespace().emit(event, payload);
  }

  getNamespace(): Namespace {
    return getMonitoringNamespace();
  }

  handleConnection(socket: Socket): void {
    socket.emit("monitoring:ready", { connected: true });
  }
}

