import { AdminRole } from "@prisma/client";

import { AppError } from "../../utils/app-error.js";
import { AdminUsersService } from "./admin-users.service.js";
import { AdminUsersRepository } from "./admin-users.repository.js";

function repo(overrides: Record<string, unknown>): AdminUsersRepository {
  const base: Record<string, unknown> = {
    list: async () => [],
    findById: async () => null,
    findByUsername: async () => null,
    create: async (data: Record<string, unknown>) => ({ id: "new", ...data }),
    update: async (id: string, data: Record<string, unknown>) => ({ id, ...data }),
    delete: async () => ({}),
    countOtherActiveSuperAdmins: async () => 1
  };
  return { ...base, ...overrides } as unknown as AdminUsersRepository;
}

describe("AdminUsersService", () => {
  it("rejects creating a user whose username is taken", async () => {
    const service = new AdminUsersService(
      repo({ findByUsername: async () => ({ id: "x" }) as never })
    );
    await expect(
      service.create({ username: "taken", password: "password1", role: AdminRole.ADMIN })
    ).rejects.toMatchObject({ code: "USERNAME_TAKEN" });
  });

  it("hashes the password and creates the user", async () => {
    let createdHash = "";
    const service = new AdminUsersService(
      repo({
        create: async (data: never) => {
          createdHash = (data as { passwordHash: string }).passwordHash;
          return { id: "1" } as never;
        }
      })
    );
    await service.create({ username: "newuser", password: "secret123", role: AdminRole.TEACHER });
    expect(createdHash).not.toBe("");
    expect(createdHash).not.toBe("secret123");
  });

  it("blocks demoting the last active super admin", async () => {
    const service = new AdminUsersService(
      repo({
        findById: async () => ({ id: "1", username: "root", role: AdminRole.SUPER_ADMIN, isActive: true }) as never,
        countOtherActiveSuperAdmins: async () => 0
      })
    );
    await expect(
      service.update("1", "someone", { role: AdminRole.ADMIN })
    ).rejects.toMatchObject({ code: "LAST_SUPER_ADMIN" });
  });

  it("allows demoting a super admin when another active one exists", async () => {
    const service = new AdminUsersService(
      repo({
        findById: async () => ({ id: "1", username: "root", role: AdminRole.SUPER_ADMIN, isActive: true }) as never,
        countOtherActiveSuperAdmins: async () => 1
      })
    );
    await expect(service.update("1", "someone", { role: AdminRole.ADMIN })).resolves.toBeDefined();
  });

  it("prevents deactivating your own account", async () => {
    const service = new AdminUsersService(
      repo({
        findById: async () => ({ id: "me", username: "me", role: AdminRole.ADMIN, isActive: true }) as never
      })
    );
    await expect(
      service.update("me", "me", { isActive: false })
    ).rejects.toMatchObject({ code: "SELF_DEACTIVATION" });
  });

  it("prevents deleting your own account", async () => {
    const service = new AdminUsersService(
      repo({ findById: async () => ({ id: "me", role: AdminRole.ADMIN, isActive: true }) as never })
    );
    await expect(service.delete("me", "me")).rejects.toMatchObject({ code: "SELF_DELETION" });
  });

  it("404s when updating a missing user", async () => {
    const service = new AdminUsersService(repo({ findById: async () => null }));
    const error = await service.update("ghost", "admin", { role: AdminRole.ADMIN }).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(AppError);
    expect((error as AppError).code).toBe("ADMIN_USER_NOT_FOUND");
  });
});
