module.exports = {
	norpc: false, 
	compileCommand: 'truffle compile', 
	skipFiles: ['Migrations.sol'],
	testCommand: 'export ETHEREUM_RPC_PORT=8555&& truffle test --network coverage --timeout 10000', 
}