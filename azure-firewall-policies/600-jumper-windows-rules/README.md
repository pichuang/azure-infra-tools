

## Add a Binary (or Executable, or Program) to PATH on Windows

```powershell
mkdir C:\bin
setx PATH "C:\bin;%PATH%"
where.exe kubectl.exe
```

