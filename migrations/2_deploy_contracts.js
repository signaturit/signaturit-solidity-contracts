const v4 = require('uuid');

var File = artifacts.require("./File.sol");
var User = artifacts.require("./User.sol");
var SignaturitUser = artifacts.require("./SignaturitUser.sol")
var Event = artifacts.require("./Event.sol");
var Payment = artifacts.require("./Payment.sol");
var Document = artifacts.require("./Document.sol");
var Signature = artifacts.require("./Signature.sol");
var TimeLogger = artifacts.require("./TimeLogger.sol");
var Certificate = artifacts.require("./Certificate.sol");
var CertifiedFile = artifacts.require("./CertifiedFile.sol");
var CertifiedFileChecker = artifacts.require("./CertifiedFileChecker.sol");
var CertifiedEmail = artifacts.require("./CertifiedEmail.sol");
var SignatureDeployer = artifacts.require("./SignatureDeployer.sol");
var CertifiedEmailDeployer = artifacts.require("./CertifiedEmailDeployer.sol");
var CertifiedFileAggregator = artifacts.require("./CertifiedFileAggregator.sol");
var SignatureAggregator = artifacts.require("./SignatureAggregator.sol");
var CertifiedEmailAggregator = artifacts.require("./CertifiedEmailAggregator.sol");

var signatureDeployerAddress;
var certifiedEmailDeployerAddress;

module.exports = async function(deployer, network, accounts) {
//there is no better way to do this with await until this is solved: https://github.com/trufflesuite/truffle/issues/501
    deployer.then(async () => {
        const signatureDeployerInstance = await deployer.deploy(
            SignatureDeployer
        );

        var tx = await web3.eth.getTransactionReceipt(signatureDeployerInstance.transactionHash);
        console.log("GAS USED FOR SIGNATURE DEPLOYER: " + tx.cumulativeGasUsed);

        const signaturitUser = await deployer.deploy(
            SignaturitUser,
            accounts[0]
        );

        tx = await web3.eth.getTransactionReceipt(signaturitUser.transactionHash);
        console.log("GAS USED FOR SIGNATURITUSER: " + tx.cumulativeGasUsed);

        
        const signatureInstance = await deployer.deploy(
            Signature,
            v4(),
            signatureDeployerInstance.address,
            Date.now(),
            accounts[0],
            signaturitUser.address
        );
        
        tx = await web3.eth.getTransactionReceipt(signatureInstance.transactionHash);
        console.log("GAS USED FOR SIGNATURE: " + tx.cumulativeGasUsed);

        const certifiedEmailDeployerInstance = await deployer.deploy(
            CertifiedEmailDeployer
        );
            
        tx = await web3.eth.getTransactionReceipt(certifiedEmailDeployerInstance.transactionHash);
        console.log("GAS USED FOR CERTIFIED EMAIL DEPLOYER: " + tx.cumulativeGasUsed);
        
        const certifiedEmailInstance = await deployer.deploy(
            CertifiedEmail,
            'certified email id',
            'certified email subject hash',
            'certified email body hash',
            'certified email delivery type',
            1500,
            certifiedEmailDeployerInstance.address,
            accounts[0],
            signaturitUser.address
        );
        
        tx = await web3.eth.getTransactionReceipt(certifiedEmailInstance.transactionHash);
        console.log("GAS USED FOR CERTIFIED EMAIL: " + tx.cumulativeGasUsed);
        
        const documentInstance = await deployer.deploy(
            Document,
            v4(),
            signatureDeployerInstance.address
        );
            
        tx = await web3.eth.getTransactionReceipt(documentInstance.transactionHash);
        console.log("GAS USED FOR DOCUMENT: " + tx.cumulativeGasUsed);
            
        const fileInstance = await deployer.deploy(File, v4());
            
        tx = await web3.eth.getTransactionReceipt(fileInstance.transactionHash);
        console.log("GAS USED FOR FILE: " + tx.cumulativeGasUsed);

        const userInstance = await deployer.deploy(
            User,
            accounts[2]
        );
        
        tx = await web3.eth.getTransactionReceipt(userInstance.transactionHash);
        console.log("GAS USED FOR USER: " + tx.cumulativeGasUsed);
        
        const certificateInstance = await deployer.deploy(
            Certificate,
            v4(),
            certifiedEmailDeployerInstance.address
            );
            
        tx = await web3.eth.getTransactionReceipt(certificateInstance.transactionHash);
        console.log("GAS USED FOR CERTIFICATE: " + tx.cumulativeGasUsed);

        const eventInstance = await deployer.deploy(
            Event,
            'event id',
            'event type',
            'event user agent',
            1500
        );
            
        tx = await web3.eth.getTransactionReceipt(eventInstance.transactionHash);
        console.log("GAS USED FOR EVENT: " + tx.cumulativeGasUsed);
        
        const paymentInstance = await deployer.deploy(
            Payment,
            userInstance.address,
            signatureInstance.address,
            'contractId'
        );
        
        tx = await web3.eth.getTransactionReceipt(paymentInstance.transactionHash);
        console.log("GAS USED FOR PAYMENT: " + tx.cumulativeGasUsed);

        const timeLoggerInstance = await deployer.deploy(
            TimeLogger,
            userInstance.address,
            userInstance.address,
            signatureInstance.address,
            v4(),
            v4(),
            Date.now(),
            Date.now(),
            20,
            -1
        );
            
        tx = await web3.eth.getTransactionReceipt(timeLoggerInstance.transactionHash);
        console.log("GAS USED FOR TIMELOGGER: " + tx.cumulativeGasUsed);
        
        const certifiedFileInstance = await deployer.deploy(
            CertifiedFile,
            accounts[1],
            signaturitUser.address,
            v4(),
            '1lqnflkahdfahfnadslfnasdfbqwr2j3rñ2ljsaldjf',
            Date.now(),
            1500
        );
        
        tx = await web3.eth.getTransactionReceipt(certifiedFileInstance.transactionHash);
        console.log("GAS USED FOR CERTIFIED FILE: " + tx.cumulativeGasUsed);

        const certifiedFileChecker = await deployer.deploy(
            CertifiedFileChecker
        );

        tx = await web3.eth.getTransactionReceipt(certifiedFileChecker.transactionHash);
        console.log("GAS USED FOR CERTIFIED FILE CHECKER: " + tx.cumulativeGasUsed);

        const certifiedFileAggregator = await deployer.deploy(
            CertifiedFileAggregator,
            signaturitUser.address
        );

        tx = await web3.eth.getTransactionReceipt(certifiedFileAggregator.transactionHash);
        console.log("GAS USED FOR CERTIFIED FILE AGGREGATOR: " + tx.cumulativeGasUsed);

        const signatureAggregator = await deployer.deploy(
            SignatureAggregator,
            signaturitUser.address
        );

        tx = await web3.eth.getTransactionReceipt(signatureAggregator.transactionHash);
        console.log("GAS USED FOR SIGNATURE AGGREGATOR: " + tx.cumulativeGasUsed);
    
        const certifiedEmailAggregator = await deployer.deploy(
            CertifiedEmailAggregator,
            signaturitUser.address
        );

        tx = await web3.eth.getTransactionReceipt(certifiedEmailAggregator.transactionHash);
        console.log("GAS USED FOR CERTIFIED EMAIL AGGREGATOR: " + tx.cumulativeGasUsed);
    })
};
