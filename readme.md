## 开发相关

### pipeline语法校验
+ 地址 https://newjenkins.avalongames.com/pipeline-model-converter/validate
+ 快捷键 shift + alt + v

## 开始使用

### 自定义格式说明
value(propId1:propValue1，propId2:propValue2)
上面的字符串表示，值为value，包含两个字段，字段名propId1对应的值为propValue1，字段名propId2对应的值为propValue2；如果是数组，以英文逗号分隔

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
+ 环境变量说明

<style>
table th:first-of-type {
    width: 160px;
}
table th:nth-of-type(2) {
    width: 20px;
}
table th:nth-of-type(3) {
    width: 100px;
}
table th:nth-of-type(4) {

}
table th:nth-of-type(5) {
    width: 100px;
}

</style>

| 变量名称 | 是否必填 | 含义 | 解析类型 | 示例 |
| --- | --- | --- | --- | --- | --- |
| CD_REPO | 是 | 仓库地址，git仓库末尾需要包含.git | string | http://git.avalongames.com/website/gm_website_server.git |
| CD_APPS | 是 | 应用列表，根目录为仓库| 数组，元素格式=应用的相对目录(<br>部署名称:【可选,交付时应用的名字，默认使用相对目录的最后一段】<br>jar包路径:【可选,jar包路径：参数，mvn生成的jar包路径，仅java应用时生效，并且必须】<br>)  | (部署名称:gameWebsiteServer，jar包路径:cat-global/target/catWebsite.jar) |
| CD_ZIP_ROOT | 否 | zip包的根目录，默认空字符串 | string | |
| CD_ZIP_PREFIX | 否 | zip包的前缀，运维有强制要求，不配置时默认使用jenkins工程名 | string | |
| CD_JIRA_KEY | 是 | jira项目的key | string | GW |
| CD_SERVERS | 是 | 服务器列表 | 数组，元素格式=显示名称(ip:ssh的ip,端口:ssh的端口,user:可选,运行应用的linux用户,默认=webuser,是否sudo:操作应用时是否sudo,true或false,部署目录:应用部署目录) | 1.ip:<br>2.端口:<br>3.user:参数,<br>4.是否sudo:<br>5.部署目录: | 内网开发(ip:192.168.200.157，端口:22，是否sudo:false，部署目录:/home/webuser/project/website) |
| CD_FTP_PATH | 是 | ftp上传地址 | string | corp/SDK/global/server |
| CD_VERSION_W_DATA | 否 | 版本号W位，影响包名，默认包名不追加该段格式 | 数组，元素格式=string | release,cn,global,dev |
| CD_CUSTOM_PARAM | 否 | 自定义参数，配合自定义构建脚本、自定义更新脚本使用 | 数组，元素格式=(字段名:表单id，描述:xx，表单类型:xx，默认值:xx，选项:xx) |  |

+ 示例：以下为OA工具的环境变量配置示例

```
CD_REPO=http://git.avalongames.com/oa_tools/oa_tools.git
CD_APPS=FrontEnd,OaToolsManage
CD_ZIP_ROOT=web
CD_JIRA_KEY=OA
CD_SERVERS=内网测试(user:webuser，ip:192.168.200.217，端口:22，是否sudo:false，部署目录:/online/web/oatools)
CD_FTP_PATH=corp/OaTools

```