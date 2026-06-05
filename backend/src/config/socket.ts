import type { Namespace, Server } from "socket.io";

let ioServer: Server | null = null;

export function setSocketServer(io: Server): void {
  ioServer = io;
}

export function getSocketServer(): Server {
  if (ioServer === null) {
    throw new Error("Socket server has not been initialized");
  }
  return ioServer;
}

export function getMonitoringNamespace(): Namespace {
  return getSocketServer().of("/admin/monitoring");
}

