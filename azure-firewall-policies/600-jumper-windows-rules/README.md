

## Add a Binary (or Executable, or Program) to PATH on Windows

```powershell
mkdir C:\bin
setx PATH "C:\bin;%PATH%"
where.exe kubectl.exe
```

## Download the Binary

```
curl -Lo kubectl.exe https://dl.k8s.io/release/v1.28.3/bin/windows/amd64/kubectl.exe
```