pipeline {
    environment {
        BRANCH_NAME = "${GIT_BRANCH.split("/")[1]}"
    }

    agent {
        node {
            label 'WebJenkins'
        }
    } 

    stages {
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
