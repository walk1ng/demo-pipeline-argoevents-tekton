这个项目是用于演示如何用argo-events、tekton、vault实现一个代码提交即触发的流水线，基础环境的配置和部署方法可以参考[这个项目](https://github.com/lanbingcloud/demo-vcluster-tekton-argoevents-vaultagent-externalsecrets)。

除了基础环境配置信息外，此项目还需要另外两个代码库协同工作：

1. [demo-user-project](https://github.com/lanbingcloud/demo-user-project)：用于存储需要做持续集成的应用源码和流水线。
2. [demo-user-deployments](https://github.com/lanbingcloud/demo-user-deployments)：用于存储部署应用所需的k8s资源文件。

首先需要准备一个k8s集群和一个vault实例，然后按照以下步骤进行部署（所需的命令行在cmds目录下）：

1. 在vault中创建如下secret：
   1) 用于存放cert-manger所需的证书和私钥的secret。
   2) 用于argoevents在github上创建webhook的secret。
   3) 用于流水线向github的package仓库提交容器镜像的secret。
   4) 用于流水线修改应用部署配置的secret。
2. 手动在集群中安装argocd以及argocd-server的patch。
3. 将项目根目录的project.yaml和app.yaml安装到集群中。
4. argocd会根据配置在物理集群中安装metallb、traefik、cert-manager、vault（包括认证所需的sa）、external-secrets、并创建一个vcluster，等待初始化完成。
5. 在vault中创建一个物理集群kubernetes认证，填写物理集群的api-server地址、ca证书、认证sa的token。然后在此认证下创建1.1 secret的访问权限。
6. 通过vcluster命名空间下的secret生成用于访问虚拟集群的kubeconfig文件，并修改server字段中的ip、端口、cluster名称等。
7. 通过argocd命令行使用kubeconfig文件向argocd注册新创建的虚拟集群。
8. 物理集群的argocd自动向虚拟集群中部署argocd，以及用于虚拟集群内部初始化所需的project和app资源。
9. 等待虚拟集群内部的argocd完成所有工具的部署，包括：argo-events、tekton、traefik、vault（包括认证所需的sa）、external-secrets、以及用户流水线命名空间。
10. 在vault中创建一个虚拟集群kubernetes认证，填写虚拟集群的api-server地址、ca证书、认证sa的token。然后在此认证下创建1.2 1.3 1.4 secret的访问权限。

等待上述部署全部完成后，在[demo-user-project](https://github.com/lanbingcloud/demo-user-project)中提交代码，即可在user-pipelines命名空间中观察到流水线的执行过程。流水线执行完成后可以在[包仓库](https://github.com/orgs/lanbingcloud/packages)看到新的镜像标签，并在[demo-user-deployments](https://github.com/lanbingcloud/demo-user-deployments)中看到修改后的k8s资源文件。