## build `quay.io/nikzainalgroup/signature.tools.lib`

```
git clone https://github.com/Nik-Zainal-Group/signature.tools.lib
cd signature.tools.lib
git checkout ${tag_no}   #checkout the required commit or tag
cd ../
docker build --platform linux/amd64 -t quay.io/nikzainalgroup/signature.tools.lib:${tag_no} .
```

## build `quay.io/nikzainalgroup/utility.scripts`

```
git clone https://github.com/Nik-Zainal-Group/utility.scripts
cd utility.scripts
git checkout dev     #checkout the required commit or tag
cd ../
docker build --platform linux/amd64 -t quay.io/nikzainalgroup/utility.scripts:latest .
```
