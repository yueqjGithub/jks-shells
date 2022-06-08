pipeline {
    agent {
        node {
            label 'WebJenkins'
        }
    }

    environment {
        CD_GIT_CRED = 'e2972996-6557-42ba-8f14-045b927e177e'
    }

    parameters {
        listGitBranches(
            name: 'CD_BRANCH',
            description: 'svn/git的tag/branch列表',
            remoteURL: env.CD_REPO_HTTP,
            credentialsId: env.CD_GIT_CRED,
            defaultValue: 'main',
            type: 'PT_BRANCH_TAG',
        )
    }

    stages {
        // stage('拉取统一构建脚本') {
        //     steps {
        //         sh 'rm -rf ${WORKSPACE}'
        //         sh 'mkdir ${WORKSPACE}'
        //         // sh 'git clone --depth=1 "git@git.avalongames.com:web_util/avalon_web_cd.git"'
        //     }
        // }

        stage('参数检查') {
            steps {
                sh "source ./util.sh && avalon_web_cd_check_param"
            }
        }

        stage('拉取项目仓库') {
            steps {
                sh "source ./util.sh && avalon_web_cd_pull_repo ${env.CD_REPO_HTTP} ${env.CD_BRANCH} ${env.CD_SVN_VERSION}"
            }
        }
    }

    post {
        // 构建后删除整个工作目录
        always {
            cleanWs()
        }
    }
}
