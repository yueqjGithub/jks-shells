pipeline {


    agent {
        node {
            label 'WebJenkins'
        }
    } 

    parameters {
        gitParameter name: 'BRANCH_TAG',
                     type: 'PT_BRANCH_TAG',
                     defaultValue: 'master'
    }

    stages {

        stage('Example') {
            steps {
                checkout([$class: 'GitSCM',
                          branches: [[name: "${params.BRANCH_TAG}"]],
                          doGenerateSubmoduleConfigurations: false,
                          extensions: [],
                          gitTool: 'Default',
                          submoduleCfg: [],
                          userRemoteConfigs: [[url: 'https://github.com/jenkinsci/git-parameter-plugin.git']]
                        ])
            }
        }

        // stage('拉取统一构建脚本') {
        //     steps {
        //         sh 'rm -rf ${WORKSPACE}'
        //         sh 'mkdir ${WORKSPACE}'
        //         // sh 'git clone --depth=1 "git@git.avalongames.com:web_util/avalon_web_cd.git"'
        //     }
        // }

        stage('拉取项目仓库') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_pull_repo "${CD_REPO}" "${branch}" "${svnVersion}"'
            }
        }
    }
}
