contract('SignaturitUser', async (accounts) => {
    const ArtifactUser = artifacts.require('SignaturitUser');

    let userContract;

    const rootAddress = accounts[0];
    const ownerAddress = accounts[1];
    const invalidAccount = accounts[2];

    const undefinedKey = "undefined key";
    const key = 'key';
    const stringValue = 'value';
    const newStringValue = 'newValue';
    const numberValue = 234;
    const newNumberValue = 54647;
    const addressValue = accounts[4];
    const newAddressValue = accounts[5];
    const boolValue = true;
    const newBoolValue = false;


    beforeEach(async () => {
        userContract = await ArtifactUser.new(
            ownerAddress,
            {
                from: rootAddress
            }
        )
    });

    it("Check if it deploy correctly", async () => {
        assert.ok(userContract.address);
    });

    it("Retrieve the owner address", async () => {
        const contractOwnerAddress = await userContract.ownerAddress();

        assert.equal(contractOwnerAddress, ownerAddress);
    });

    it('Try to retrieve unstored string value', async () => {
        const unstoredString = await userContract.getStringAttribute('no-stored');

        assert.equal(unstoredString, '');
    });

    it('Set string attribute and retrieve it', async () => {
        await userContract.setStringAttribute(
            key,
            stringValue,
            {
                from: rootAddress
            }
        );

        const storedValue = await userContract.getStringAttribute(key);

        assert.equal(storedValue, stringValue);
    });

    it('Set string attribute from no owner account and retrieve it', async () => {
        try {
            await userContract.setStringAttribute(
                key,
                stringValue,
                {
                    from: invalidAccount
                }
            );
            
        } catch {
            assert.ok('ok')
            return;
        }
        
        assert.fail('This user cant perform this action');
    });

    it("Override string key and retrieve", async () => {
        await userContract.setStringAttribute(
            key,
            stringValue,
            {
                from: rootAddress
            }
        );

        await userContract.setStringAttribute(
            key,
            newStringValue,
            {
                from: rootAddress
            }
        );

        const storedValue = await userContract.getStringAttribute(key);
        assert.equal(newStringValue, storedValue);
    });

    it("Define string array key and retrieve the value", async () => {
        const firstStringValue = "first value";
        const secondStringValue = "second value";

        await userContract.setStringArrayAttribute(
            key,
            firstStringValue,
            {
                from: rootAddress
            }
        );

        await userContract.setStringArrayAttribute(
            key,
            secondStringValue,
            {
                from: rootAddress
            }
        );

        const firstStoredData = await userContract.getStringArrayAttribute(key, 0);
        const secondStoredData = await userContract.getStringArrayAttribute(key, 1);

        assert.equal(firstStoredData, firstStringValue);
        assert.equal(secondStoredData, secondStoredData);
    });

    it("Access to a non defined string key and index", async () => {
        const firstStoredData = await userContract.getStringArrayAttribute(undefinedKey, 0);
        const secondStoredData = await userContract.getStringArrayAttribute(undefinedKey, 20);
        
        assert.equal(firstStoredData, '');
        assert.equal(secondStoredData, '');
    });

    it('Try to retrieve unstored number value', async () => {
        const unstoredNumber = await userContract.getNumberAttribute('no-stored');

        assert.equal(unstoredNumber, 0);
    });

    it('Set number attribute and retrieve it', async () => {
        await userContract.setNumberAttribute(
            key,
            numberValue,
            {
                from: rootAddress
            }
        );

        const storedValue = await userContract.getNumberAttribute(key);

        assert.equal(storedValue, numberValue);
    });

    it('Set number attribute from no owner account and retrieve it', async () => {
        try {
            await userContract.setNumberAttribute(
                key,
                stringValue,
                {
                    from: invalidAccount
                }
            );
            
        } catch {
            assert.ok('ok')
            return;
        }
        
        assert.fail('This user cant perform this action');
    });

    it("Override number key and retrieve", async () => {
        await userContract.setNumberAttribute(
            key,
            numberValue,
            {
                from: rootAddress
            }
        );

        await userContract.setNumberAttribute(
            key,
            newNumberValue,
            {
                from: rootAddress
            }
        );

        const storedValue = await userContract.getNumberAttribute(key);
        assert.equal(newNumberValue, storedValue);
    });

    it("Define number array key and retrieve the value", async () => {
        const firstStringValue = 1;
        const secondStringValue = 2;

        await userContract.setNumberArrayAttribute(
            key,
            firstStringValue,
            {
                from: rootAddress
            }
        );

        await userContract.setNumberArrayAttribute(
            key,
            secondStringValue,
            {
                from: rootAddress
            }
        );

        const firstStoredData = await userContract.getNumberArrayAttribute(key, 0);
        const secondStoredData = await userContract.getNumberArrayAttribute(key, 1);

        assert.equal(firstStoredData, firstStringValue);
        assert.equal(secondStoredData, secondStoredData);
    });

    it("Access to a non defined number key and index", async () => {
        const firstStoredData = await userContract.getNumberArrayAttribute(undefinedKey, 0);
        const secondStoredData = await userContract.getNumberArrayAttribute(undefinedKey, 20);
        
        assert.equal(firstStoredData, 0);
        assert.equal(secondStoredData, 0);
    });

    it('Try to retrieve unstored address value', async () => {
        const unstoredAddress = await userContract.getAddressAttribute('no-stored');

        assert.equal(unstoredAddress, 0);
    });

    it('Set address attribute and retrieve it', async () => {
        await userContract.setAddressAttribute(
            key,
            addressValue,
            {
                from: rootAddress
            }
        );

        const storedValue = await userContract.getAddressAttribute(key);

        assert.equal(storedValue, addressValue);
    });

    it('Set address attribute from no owner account and retrieve it', async () => {
        try {
            await userContract.setAddressAttribute(
                key,
                addressValue,
                {
                    from: invalidAccount
                }
            );
            
        } catch {
            assert.ok('ok')
            return;
        }
        
        assert.fail('This user cant perform this action');
    });

    it("Override address key and retrieve", async () => {
        await userContract.setAddressAttribute(
            key,
            addressValue,
            {
                from: rootAddress
            }
        );

        await userContract.setAddressAttribute(
            key,
            newAddressValue,
            {
                from: rootAddress
            }
        );

        const storedValue = await userContract.getAddressAttribute(key);
        assert.equal(newAddressValue, storedValue);
    });

    it("Define address array key and retrieve the value", async () => {
        await userContract.setAddressArrayAttribute(
            key,
            addressValue,
            {
                from: rootAddress
            }
        );

        await userContract.setAddressArrayAttribute(
            key,
            newAddressValue,
            {
                from: rootAddress
            }
        );

        const firstStoredData = await userContract.getAddressArrayAttribute(key, 0);
        const secondStoredData = await userContract.getAddressArrayAttribute(key, 1);

        assert.equal(firstStoredData, addressValue);
        assert.equal(secondStoredData, newAddressValue);
    });

    it("Access to a non defined address key and index", async () => {
        const firstStoredData = await userContract.getAddressArrayAttribute(undefinedKey, 0);
        const secondStoredData = await userContract.getAddressArrayAttribute(undefinedKey, 20);
        
        assert.equal(firstStoredData, 0);
        assert.equal(secondStoredData, 0);
    });

    it('Try to retrieve unstored boolean value', async () => {
        const unstoredBoolean = await userContract.getBooleanAttribute('no-stored');

        assert.equal(unstoredBoolean, false);
    });

    it('Set boolean attribute and retrieve it', async () => {
        await userContract.setBooleanAttribute(
            key,
            boolValue,
            {
                from: rootAddress
            }
        );

        const storedValue = await userContract.getBooleanAttribute(key);

        assert.equal(storedValue, boolValue);
    });

    it('Set boolean attribute from no owner account and retrieve it', async () => {
        try {
            await userContract.setBooleanAttribute(
                key,
                boolValue,
                {
                    from: invalidAccount
                }
            );
            
        } catch {
            assert.ok('ok')
            return;
        }
        
        assert.fail('This user cant perform this action');
    });

    it("Override boolean key and retrieve", async () => {
        await userContract.setBooleanAttribute(
            key,
            boolValue,
            {
                from: rootAddress
            }
        );

        await userContract.setBooleanAttribute(
            key,
            newBoolValue,
            {
                from: rootAddress
            }
        );

        const storedValue = await userContract.getBooleanAttribute(key);
        assert.equal(newBoolValue, storedValue);
    });

    it("Define boolean array key and retrieve the value", async () => {
        const firstBooleanValue = false;
        const secondBooleanValue = true;
        
        await userContract.setBooleanArrayAttribute(
            key,
            firstBooleanValue,
            {
                from: rootAddress
            }
        );

        await userContract.setBooleanArrayAttribute(
            key,
            secondBooleanValue,
            {
                from: rootAddress
            }
        );

        const firstStoredData = await userContract.getBooleanArrayAttribute(key, 0);
        const secondStoredData = await userContract.getBooleanArrayAttribute(key, 1);

        assert.equal(firstStoredData, firstBooleanValue);
        assert.equal(secondStoredData, secondBooleanValue);
    });

    it("Access to a non defined boolean key and index", async () => {
        const firstStoredData = await userContract.getBooleanArrayAttribute(undefinedKey, 0);
        const secondStoredData = await userContract.getBooleanArrayAttribute(undefinedKey, 20);
        
        assert.equal(firstStoredData, false);
        assert.equal(secondStoredData, false);
    });
});