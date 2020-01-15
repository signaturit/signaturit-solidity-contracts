node ('ecs'){
    checkout scm

    def pipeline = load "/var/jenkins_home/pipeline.groovy"

    pipeline.prepareEnvironment("signaturit-solidity-contracts")

    pipeline.runPipeline(this)
}

private build(pipeline) {
  return true;
}

private deploy(pipeline) {
  sh "npm install && npm run test && npm run compile-contracts && npm run coverage";

  pipeline.slack("good")
}

private test(pipeline) {
    return true
}

private translations(pipeline) {
    return true
}

private sonarQubeScanner(pipeline) {
    pipeline.sonarQubeScanner()
}