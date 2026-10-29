from pathlib import Path
import subprocess,sys,urllib.request,re,json,zipfile
root=Path(__file__).resolve().parent
server=subprocess.Popen([sys.executable,str(root/'serve.py'),'--port','0','--no-browser'],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True)
try:
    url=server.stdout.readline().strip().split('WebLab5: ',1)[1]
    opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
    results=[]
    for name in ['index.html','LAB05.html','LAB05.js','LAB05.wasm','LAB05.pck','LAB05.audio.worklet.js','LAB05.audio.position.worklet.js','LAB05.png','LAB05.icon.png','LAB05.apple-touch-icon.png']:
        with opener.open(url+name,timeout=20) as r:
            data=r.read()
            assert r.status==200 and len(data)==(root/name).stat().st_size
            if name.endswith('.wasm'):
                assert r.headers.get_content_type()=='application/wasm' and data[:8]==b'\x00asm\x01\x00\x00\x00'
            results.append({'file':name,'bytes':len(data),'status':r.status})
    html=(root/'index.html').read_text(encoding='utf-8')
    config=json.loads(re.search(r'const GODOT_CONFIG = (.*);',html).group(1))
    for name,size in config['fileSizes'].items():assert (root/name).stat().st_size==size
    for ref in re.findall(r'(?:src|href)="([^"]+)"',html):
        if not ref.startswith(('http:','https:','#','data:')):assert (root/ref).is_file(),ref
    report={'result':'PASS','checks':['All 10 web entry/assets return HTTP 200','Export file sizes match HTML config','WASM MIME and binary header valid','HTML references exist'],'files':results,'scope':'HTTP and file integrity; browser gameplay not verified.'}
    (root/'VALIDATION.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
finally:
    server.terminate()
    server.wait(timeout=10)
archive=root.parent/'WebLab5.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in sorted(root.iterdir()):
        if p.is_file() and p.suffix!='.log' and p.name!='verify_package.py':z.write(p,'WebLab5/'+p.name)
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
print(json.dumps({'validation':'PASS','archive':str(archive),'zip_mb':round(archive.stat().st_size/1048576,2)}))
