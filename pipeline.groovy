pipeline {
    agent {
        node {
            label 'WebJenkins'
        }
    } 

    stages {
        stage('拉取统一构建脚本') {
            steps {
                sh 'rm -rf avalon_web_cd'
                sh 'git clone --depth=1 "git@git.avalongames.com:web_util/avalon_web_cd.git"'
            }
        }
    }
}
