

## Add a Binary (or Executable, or Program) to PATH on Windows

```powershell
mkdir C:\k8s-tools
setx PATH "C:\k8s-tools;%PATH%"
where.exe kubectl.exe
```

## Mkdir kubeconfig
```
mkdir $HOME\.kube
```

## Download the Binary

```
curl -Lo kubectl.exe https://dl.k8s.io/release/v1.28.3/bin/windows/amd64/kubectl.exe
```
