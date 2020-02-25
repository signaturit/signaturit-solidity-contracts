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
  sh "npm install && npm run compile-contracts";

  pipeline.slack("good")
}

private test(pipeline) {
    sh "npm install && npm run lint && npm run coverage"
}

private translations(pipeline) {
    return true
}

private sonarQubeScanner(pipeline) {
    pipeline.sonarQubeScanner()
}