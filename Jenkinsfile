// properties([
//   parameters([
//     [
//       $class: 'ChoiceParameter',
//       choiceType: 'PT_SINGLE_SELECT',
//       name: 'Environment',
//       script: [
//         $class: 'ScriptlerScript',
//         scriptlerScriptId:'Environments.groovy'
//       ]
//     ],
//     [
//       $class: 'CascadeChoiceParameter',
//       choiceType: 'PT_SINGLE_SELECT',
//       name: 'Host',
//       referencedParameters: 'Environment',
//       script: [
//         $class: 'ScriptlerScript',
//         scriptlerScriptId:'HostsInEnv.groovy',
//         parameters: [
//           [name:'Environment', value: '$Environment']
//         ]
//       ]
//    ]
//  ])
// ])

pipeline {

    def branchList

    agent {
        node {
            label 'WebJenkins'
        }
    }

    environment {
        CD_GIT_CRED = 'e2972996-6557-42ba-8f14-045b927e177e'
    }

    // parameters {
    //     // when {
    //     //     expression {
    //     //         return env.CD_REPO.contains("git.avalongames.com")
    //     //     }
            
    //         listGitBranches(
    //             name: 'CD_BRANCH',
    //             description: 'svn/git的tag/branch列表',
    //             remoteURL: env.CD_REPO,
    //             credentialsId: 'e2972996-6557-42ba-8f14-045b927e177e',
    //             defaultValue: 'main',
    //             type: 'PT_BRANCH_TAG',
    //         )
    //     // }
 
    // }

    stages {
        stage('参数检查') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_check_param'
                if(env.CD_REPO.contains("git.avalongames.com")){
                    branchList = listGitBranches(
                        name: 'CD_BRANCH',
                        description: 'svn/git的tag/branch列表',
                        remoteURL: env.CD_REPO,
                        credentialsId: 'e2972996-6557-42ba-8f14-045b927e177e',
                        defaultValue: 'main',
                        type: 'PT_BRANCH_TAG',
                    )
                }

            }
        }

        stage('拉取项目仓库') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_pull_repo ${CD_REPO} ${CD_BRANCH} ${CD_SVN_VERSION}'
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
