## 开发相关

### pipeline语法校验
+ 地址 https://newjenkins.avalongames.com/pipeline-model-converter/validate
+ 快捷键 shift + alt + v

## 开始使用

### 自定义格式说明
value(propId1:propValue1，propId2:propValue2)
上面的字符串表示，值为value，包含两个字段，字段名propId1对应的值为propValue1，字段名propId2对应的值为propValue2

### 使用条件
+ jenkins项目必须时pipeline类型的，配置从git拉取脚本
> 仓库地址 http://git.avalongames.com/web_util/avalon_web_cd.git
> 凭据选 web
> 分支选 main
+ 只适应于web平台内部项目，目前支持web前端，node后端应用，laravel应用，java应用，未识别的类型不做额外处理
+ 代码仓库只支持公司svn或公司git
+ 更新应用时，node应用需要在应用同级目录配置一个同名的pm2配置文件*.json作为启动/停止脚本，比如IAMManage和IAMManage.json
+ java应用需要在应用的根目录下配置一个同名的业务配置文件*.properties，比如SuperSDK/SuperSDK.jar和SuperSDK/SuperSDK.properties

### 使用教程
+ 每个应用支持自定义构建脚本，执行路径为应用根目录/custom-build/build.sh，在压缩成zip前执行
+ 每个应用支持自定义更新脚本，执行路径为应用根目录custom-build/before-app-start.sh，在目标服务器应用启动前执行
+ 环境变量说明，*表示必填参数，否则为可选参数:

```
# * 仓库地址，git仓库末尾需要包含.git
CD_REPO=http://git.avalongames.com/oa_tools/oa_tools.git
# * 应用列表，根目录为仓库，自定义格式说明
#       * 应用的相对目录
#               部署名称:可选参数，交付时应用的名字，默认使用相对目录的最后一段
#               jar包路径:可选参数，mvn生成的jar包路径，仅java应用时生效，并且必须
CD_APPS=FrontEnd,OaToolsManage
# zip包的根目录，默认空字符串
CD_ZIP_ROOT=web
# zip包的前缀，运维有强制要求，不配置时默认使用jenkins工程名
CD_ZIP_PREFIX=Web-OaTools
# * jira项目的key
CD_JIRA_KEY=OA
# * 服务器列表，自定义格式说明
#       * 显示名称
#               * user:运行应用的linux用户
#               * 端口:ssh端口
#               * 是否sudo:操作应用时是否sudo
#               * 部署目录:应用部署目录
CD_SERVERS=内网测试(user:webuser，ip:192.168.200.217，端口:22，是否sudo:false，部署目录:/online/web/oatools)
# * ftp上传地址
CD_FTP_PATH=corp/OaTools
# 版本号W位，影响包名，默认包名不追加该段格式
CD_VERSION_W_DATA=release,cn,global,dev

```