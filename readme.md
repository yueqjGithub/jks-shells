## 使用条件
+ 只适应于web平台内部项目，目前支持web前端，node后端应用，laravel应用，java应用，未识别的类型不做额外处理
+ 项目分支结构必须为标准结构，即xxxxx/trunk xxxx/branches/xxx xxxx/tags/xxx
+ node应用需要在应用同级目录配置一个同名的pm2配置文件*.json作为启动/停止脚本，比如IAMManage和IAMManage.json
+ java应用需要在应用的根目录下配置一个同名的业务配置文件*.properties，比如SuperSDK/SuperSDK.jar和SuperSDK/SuperSDK.properties

## 使用教程

+ 新建jenkins项目时，从web模板工程拷贝
+ 每个应用支持自定义脚本，执行路径为应用根目录/custom-build/build.sh，在压缩成zip前执行
+ 根据实际情况修改jenkins构建时的以下参数
    + ftpPath
    + appSvnDir
    + branch
    + appList 应用列表，必须为相对分支路径的全路径，比如BackEnd/IAMManage和web/FrontEnd/avalon-gbs-util-client
    + updateTarget 注意冒号为英文逗号，逗号为中文逗号
    + customShellPath 自定义脚本路径，可选参数，在压缩成zip和生成md5前执行

