contract('UserAuthority', async (accounts) => {
    const ArtifactUserAuthority = artifacts.require('UserAuthority');

    const rootAddress = accounts[0];
    const adminAddress = accounts[1];
    const secondAdminAddress = accounts[2];
    const userAddress = accounts[3];
    const secondUserAddress = accounts[4];
    const invalidAddress = accounts[5];

    let userAuthorityContract;

    const UserRole = {
        root: 3,
        admin: 2,
        user: 1
    };

    beforeEach(async () => {
        userAuthorityContract = await ArtifactUserAuthority.new(
            {
                from: rootAddress
            }
        );
    });

    it("Check if it deploy correctly", async (done) => {
        assert.ok(userAuthorityContract);
        done();
    });

    it("create admin from root account, expect to pass", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        const user = await userAuthorityContract.getUser(adminAddress);
        const isManager = await userAuthorityContract.isUserManager(adminAddress, rootAddress);
        const managedUser = await userAuthorityContract.getManagedUser(rootAddress, 0);

        assert.equal(user.outputRole.toNumber(), UserRole.admin);
        assert.ok(isManager);
        assert.equal(managedUser.adr, adminAddress);
    });

    it("create admin from admin account, expect to pass", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createAdmin(
            secondAdminAddress,
            {
                from: adminAddress
            }
        );

        const user = await userAuthorityContract.getUser(secondAdminAddress);
        const isManager = await userAuthorityContract.isUserManager(secondAdminAddress, adminAddress);
        const managedUser = await userAuthorityContract.getManagedUser(adminAddress, 0);

        assert.equal(user.outputRole.toNumber(), UserRole.admin);
        assert.ok(isManager);
        assert.equal(managedUser.adr, secondAdminAddress);
    });

    it("create admin from user account, expect exception", async () => {
        await userAuthorityContract.createUser(userAddress);

        try {
            await userAuthorityContract.createAdmin(
                adminAddress,
                {
                    from: userAddress
                }
            );
        } catch(error) {
            assert.include(error.message, "The account can't perform this action");
        }

        const isManager = await userAuthorityContract.isUserManager(adminAddress, userAddress);
        const managedUser = await userAuthorityContract.getManagedUser(userAddress, 0);

        assert.ok(!isManager);
        assert.equal(parseInt(managedUser.adr), 0);
    });

    it("create user from user account, expect exception", async () => {
        await userAuthorityContract.createUser(userAddress);

        try {
            await userAuthorityContract.createUser(
                secondUserAddress,
                {
                    from: userAddress
                }
            );
        } catch(error) {
            assert.include(error.message, "The account can't perform this action");
        }

        const isManager = await userAuthorityContract.isUserManager(secondUserAddress, userAddress);
        const managedUser = await userAuthorityContract.getManagedUser(userAddress, 0);

        assert.ok(!isManager);
        assert.equal(parseInt(managedUser.adr), 0);
    });

    it("Set user contract from manager, expect to pass", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        await userAuthorityContract.setUserContract(
            userAddress,
            secondUserAddress,
            {
                from: adminAddress
            }
        );

        const user = await userAuthorityContract.getUser(userAddress);

        assert.equal(user.contractAddress, secondUserAddress);
    });

    it("Set user contract from another manager, expect exception", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createAdmin(secondAdminAddress);

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        try {
            await userAuthorityContract.setUserContract(
                userAddress,
                secondUserAddress,
                {
                    from: secondAdminAddress
                }
            );
        } catch(error) {
            assert.include(error.message, "Unauthorized action")
        }
    });

    it("Set user contract from user, expect exception", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        await userAuthorityContract.createUser(secondUserAddress, {from: adminAddress});

        try {
            await userAuthorityContract.setUserContract(
                userAddress,
                adminAddress,
                {
                    from: secondUserAddress
                }
            );
        } catch(error) {
            assert.include(error.message, "Unauthorized action")
        }
    });

    it("Set user role as admin from manager, expect to pass", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        await userAuthorityContract.setRole(
            userAddress,
            UserRole.admin,
            {
                from: adminAddress
            }
        );

        const user = await userAuthorityContract.getUser(userAddress);

        assert.equal(user.outputRole.toNumber(), UserRole.admin);
    });

    it("Set user role as admin from another manager, expect exception", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createAdmin(secondAdminAddress, {from: adminAddress});

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        try {
            await userAuthorityContract.setRole(
                userAddress,
                UserRole.admin,
                {
                    from: secondAdminAddress
                }
            );
        }catch(error) {
            assert.include(error.message, "Unauthorized action");
        }

        const user = await userAuthorityContract.getUser(userAddress);

        assert.equal(user.outputRole.toNumber(), UserRole.user);
    });

    it("Set user role as admin from user, expect exception", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        try {
            await userAuthorityContract.setRole(
                userAddress,
                UserRole.user,
                {
                    from: userAddress
                }
            );
        }catch(error) {
            assert.include(error.message, "Unauthorized action");
        }
        
        const user = await userAuthorityContract.getUser(userAddress);

        assert.equal(user.outputRole.toNumber(), UserRole.user);
    });

    it("Set user role as root from manager, expect exception", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        try {
            await userAuthorityContract.setRole(
                userAddress,
                UserRole.root,
                {
                    from: adminAddress
                }
            );
        }catch(error) {
            assert.include(error.message, "Can't set an higher role");
        }

        const user = await userAuthorityContract.getUser(userAddress);

        assert.equal(user.outputRole.toNumber(), UserRole.user);
    });

    it("Set user reputation as admin from manager, expect to pass", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        const userBefore = await userAuthorityContract.getUser(userAddress);

        assert.equal(userBefore.outputReputation.toNumber(), 3);

        await userAuthorityContract.setReputation(
            userAddress,
            1,
            {
                from: adminAddress
            }
        );

        const userAfter = await userAuthorityContract.getUser(userAddress);

        assert.equal(userAfter.outputReputation.toNumber(), 1);
    });

    it("Set user reputation as admin from another manager, expect exception", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createAdmin(secondAdminAddress, {from: adminAddress});

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        try {
            await userAuthorityContract.setReputation(
                userAddress,
                1,
                {
                    from: secondAdminAddress
                }
            );
        }catch(error) {
            assert.include(error.message, "Unauthorized action");
        }

        const user = await userAuthorityContract.getUser(userAddress);

        assert.equal(user.outputReputation.toNumber(), 3);
    });

    it("Set user reputation as admin from admin reduced to user, expect exception", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        await userAuthorityContract.setRole(adminAddress, UserRole.user);
        
        try {
            await userAuthorityContract.setReputation(
                userAddress,
                1,
                {
                    from: adminAddress
                }
            );
        }catch(error) {
            assert.include(error.message, "Unauthorized action");
        }

        const user = await userAuthorityContract.getUser(userAddress);

        assert.equal(user.outputReputation.toNumber(), 3);
    });

    it("Set user reputation as admin from user, expect exception", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        try {
            await userAuthorityContract.setReputation(
                secondUserAddress,
                1,
                {
                    from: userAddress
                }
            );
        }catch(error) {
            assert.include(error.message, "Unauthorized action");
        }

        const user = await userAuthorityContract.getUser(userAddress);

        assert.equal(user.outputReputation.toNumber(), 3);
    });

    it("Set user validity as admin from manager, expect to pass", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        const userBefore = await userAuthorityContract.getUser(userAddress);

        assert.equal(userBefore.outputReputation.toNumber(), 3);

        await userAuthorityContract.setValidity(
            userAddress,
            false,
            {
                from: adminAddress
            }
        );

        const userAfter = await userAuthorityContract.getUser(userAddress);

        assert.equal(userAfter.validity, false);
    });

    it("Set user validity as admin from another manager, expect exception", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createAdmin(secondAdminAddress, {from: adminAddress});

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        try {
            await userAuthorityContract.setValidity(
                userAddress,
                false,
                {
                    from: secondAdminAddress
                }
            );
        }catch(error) {
            assert.include(error.message, "Unauthorized action");
        }

        const user = await userAuthorityContract.getUser(userAddress);

        assert.equal(user.validity, true);
    });

    it("Set user validity as admin from user, expect exception", async () => {
        await userAuthorityContract.createAdmin(adminAddress);

        await userAuthorityContract.createUser(userAddress, {from: adminAddress});

        try {
            await userAuthorityContract.setValidity(
                secondUserAddress,
                false,
                {
                    from: userAddress
                }
            );
        }catch(error) {
            assert.include(error.message, "Unauthorized action");
        }

        const user = await userAuthorityContract.getUser(userAddress);

        assert.equal(user.validity, true);
    });

    it("Create AdminAndUser from root account, expect to pass", async () => {
        await userAuthorityContract.createAdminAndUser(adminAddress, userAddress, {from: rootAddress});

        const userAdmin = await userAuthorityContract.getUser(adminAddress);
        const user = await userAuthorityContract.getUser(userAddress);
        const isRootAdminManager = await userAuthorityContract.isUserManager(adminAddress, rootAddress);
        const isAdminUserManager = await userAuthorityContract.isUserManager(userAddress, adminAddress);
        const managedRootUser = await userAuthorityContract.getManagedUser(rootAddress, 0);
        const managedAdminUser = await userAuthorityContract.getManagedUser(adminAddress, 0);

        assert.equal(userAdmin.outputRole.toNumber(), UserRole.admin);
        assert.equal(user.outputRole.toNumber(), UserRole.user);
        assert.ok(isRootAdminManager);
        assert.ok(isAdminUserManager);

        assert.equal(managedRootUser.adr, adminAddress);
        assert.equal(managedAdminUser.adr, userAddress);

    });

    it("Create AdminAndUser from non root account, expect exception", async () => {
        try {
            await userAuthorityContract.createAdminAndUser(adminAddress, userAddress, {from: adminAddress});

            assert.fail("It should have thrown")
        } catch(error) {
            assert.include(error.message, "The account can't perform this action");
        }
    });
})
