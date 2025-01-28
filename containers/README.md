## build `quay.io/nikzainalgroup/signature.tools.lib`

```
git clone https://github.com/Nik-Zainal-Group/signature.tools.lib
docker build --platform linux/amd64 -t quay.io/nikzainalgroup/signature.tools.lib:${tag_no} .
```

## build `quay.io/nikzainalgroup/utility.scripts`

```
git clone https://github.com/Nik-Zainal-Group/utility.scripts
cd utility.scripts
git checkout dev
cd ../
docker build --platform linux/amd64 -t quay.io/nikzainalgroup/utility.scripts:latest .
```
