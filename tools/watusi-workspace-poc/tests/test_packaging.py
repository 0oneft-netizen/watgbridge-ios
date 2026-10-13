import pathlib, sys, struct, unittest, tempfile, zipfile, plistlib
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parents[1]))
from package_ipa import add_load_command,package,LIBRARY

def binary(encrypted=0,padding=True):
    header=struct.pack('<IIIIIIII',0xfeedfacf,0x100000c,0,2,2,176,0,0)
    segment=struct.pack('<II16sQQQQIIII',0x19,152,b'__TEXT',0,4096,0,4096,7,5,1,0)
    section=struct.pack('<16s16sQQIIIIIIII',b'__text',b'__TEXT',512,16,512,0,0,0,0,0,0,0)
    crypt=struct.pack('<IIIIII',0x2c,24,512,16,encrypted,0)
    return header+segment+section+crypt+(b'\0' if padding else b'x')*304+b'CODE'*4

class Tests(unittest.TestCase):
    def test_preserves_all_code_bytes(self):
        original=binary(); result=add_load_command(original)
        self.assertEqual(len(result),len(original)); self.assertEqual(result[512:],original[512:])
        self.assertIn(LIBRARY,result); self.assertEqual(struct.unpack_from('<I',result,16)[0],3)
    def test_refuses_encryption_and_occupied_padding(self):
        for data in (binary(1),binary(padding=False),b'x'):
            with self.assertRaises(ValueError): add_load_command(data)
    def test_duplicate_injection_refused(self):
        with self.assertRaises(ValueError): add_load_command(add_load_command(binary()))
    def test_only_binary_and_new_addon_changed(self):
        with tempfile.TemporaryDirectory() as d:
            root=pathlib.Path(d); source=root/'input.ipa'; addon=root/'addon';output=root/'out.ipa'
            addon.write_bytes(binary()); info={'CFBundleIdentifier':'com.fouadraheb.watusiSMB','CFBundleExecutable':'WhatsApp','CFBundleShortVersionString':'26.38.74'}
            with zipfile.ZipFile(source,'w') as z:
                z.writestr('Payload/WhatsApp.app/Info.plist',plistlib.dumps(info))
                z.writestr('Payload/WhatsApp.app/WhatsApp',binary())
                z.writestr('Payload/WhatsApp.app/Watusi.dylib',b'unchanged')
            package(source,addon,output)
            with zipfile.ZipFile(output) as z: self.assertEqual(z.read('Payload/WhatsApp.app/Watusi.dylib'),b'unchanged')
            with self.assertRaises(ValueError): package(source,addon,output)
    def test_original_bundle_not_silently_installed(self):
        with tempfile.TemporaryDirectory() as d:
            root=pathlib.Path(d);source=root/'input.ipa';addon=root/'addon';addon.write_bytes(binary())
            info={'CFBundleIdentifier':'net.whatsapp.WhatsAppSMB','CFBundleExecutable':'WhatsApp','CFBundleShortVersionString':'26.38.74'}
            with zipfile.ZipFile(source,'w') as z:
                z.writestr('Payload/WhatsApp.app/Info.plist',plistlib.dumps(info));z.writestr('Payload/WhatsApp.app/WhatsApp',binary())
            with self.assertRaises(ValueError):package(source,addon,root/'out.ipa')

if __name__=='__main__': unittest.main()
