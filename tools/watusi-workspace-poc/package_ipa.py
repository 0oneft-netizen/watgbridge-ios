"""Add the separately built addon to an unencrypted, compatible duplicate IPA.

No signing, encryption removal, offset relocation, or backend changes.
The resulting IPA must be signed by the user's existing installer.
"""
import argparse
import pathlib
import plistlib
import struct
import zipfile

LIBRARY = b'@executable_path/WBGWorkspace.dylib\0'

def add_load_command(data):
    data = bytearray(data)
    if data[:4] == b'\xca\xfe\xba\xbe':
        count = struct.unpack_from('>I', data, 4)[0]
        if count > 8: raise ValueError('Unsupported fat architecture count')
        for i in range(count):
            cpu, subtype, offset, size, align = struct.unpack_from('>IIIII', data, 8 + i * 20)
            if cpu != 0x100000c: raise ValueError('Only arm64 slices are supported')
            changed = add_load_command(data[offset:offset+size])
            data[offset:offset+size] = changed
        return bytes(data)
    if len(data) < 32 or data[:4] != b'\xcf\xfa\xed\xfe':
        raise ValueError('Expected little endian 64-bit Mach-O')
    cpu = struct.unpack_from('<I', data, 4)[0]
    if cpu != 0x100000c: raise ValueError('Expected arm64')
    count, commands_size = struct.unpack_from('<II', data, 16)
    end = 32 + commands_size
    if end > len(data): raise ValueError('Truncated commands')
    pos = 32
    for i in range(count):
        if pos + 8 > end: raise ValueError('Truncated load command')
        cmd, size = struct.unpack_from('<II', data, pos)
        if size < 8 or size % 8 or pos + size > end: raise ValueError('Invalid load command')
        if cmd == 0x2c and struct.unpack_from('<I', data, pos+16)[0]:
            raise ValueError('Encrypted executable; cannot package')
        if cmd in (0xc, 0x80000018, 0x8000001f):
            start = pos + struct.unpack_from('<I', data, pos+8)[0]
            if bytes(data[start:pos+size]).split(b'\0',1)[0] == LIBRARY[:-1]:
                raise ValueError('Addon already present')
        pos += size
    if pos != end: raise ValueError('Command size mismatch')
    command_size = (24 + len(LIBRARY) + 7) // 8 * 8
    # Header slack must be entirely unused and precede every file-backed section.
    first_section = len(data)
    pos = 32
    for i in range(count):
        cmd, size = struct.unpack_from('<II', data, pos)
        if cmd == 0x19:
            if size < 72: raise ValueError('Truncated segment')
            sections = struct.unpack_from('<I', data, pos+64)[0]
            if size < 72 + sections*80: raise ValueError('Truncated sections')
            for j in range(sections):
                section = pos + 72 + j*80
                offset = struct.unpack_from('<I', data, section+48)[0]
                section_type = struct.unpack_from('<I', data, section+64)[0] & 0xff
                if offset and section_type not in (1,12,18): first_section = min(first_section,offset)
        pos += size
    if end + command_size > first_section or end + command_size > len(data):
        raise ValueError('Insufficient load-command padding; refusing to move binary offsets')
    if any(data[end:end+command_size]): raise ValueError('Load-command padding is occupied')
    command = struct.pack('<IIIIII',0xc,command_size,24,0,0,0) + LIBRARY
    data[end:end+command_size] = command.ljust(command_size,b'\0')
    struct.pack_into('<II',data,16,count+1,commands_size+command_size)
    return bytes(data)

def package(source, addon, output, allow_original=False):
    source,addon,output=map(pathlib.Path,(source,addon,output))
    if output.exists(): raise ValueError('Output already exists')
    library=addon.read_bytes()
    if library[:4] != b'\xcf\xfa\xed\xfe' or struct.unpack_from('<I',library,4)[0] != 0x100000c:
        raise ValueError('Expected Apple-built arm64 addon')
    with zipfile.ZipFile(source) as archive:
        names=archive.namelist()
        if len(set(names)) != len(names): raise ValueError('Duplicate ZIP entries')
        for name in names:
            if pathlib.PurePosixPath(name).is_absolute() or '..' in pathlib.PurePosixPath(name).parts:
                raise ValueError('Unsafe archive path')
        plists=[n for n in names if n.startswith('Payload/') and n.count('/')==2 and n.endswith('/Info.plist')]
        if len(plists)!=1: raise ValueError('Expected one top-level app')
        info=plistlib.loads(archive.read(plists[0])); prefix=plists[0].rsplit('/',1)[0]+'/'
        if info.get('CFBundleShortVersionString')!='26.38.74': raise ValueError('Untested WhatsApp version')
        bundle=info.get('CFBundleIdentifier')
        allowed={'com.fouadraheb.watusi','com.fouadraheb.watusiSMB'}
        if allow_original: allowed |= {'net.whatsapp.WhatsApp','net.whatsapp.WhatsAppSMB'}
        if bundle not in allowed: raise ValueError('Use a Duplicate IPA; original bundle is blocked by default')
        executable=info.get('CFBundleExecutable','')
        if not executable or '/' in executable or executable in ('.','..'): raise ValueError('Invalid executable name')
        binary=prefix+executable; target=prefix+'WBGWorkspace.dylib'
        if target in names: raise ValueError('Addon already present')
        patched=add_load_command(archive.read(binary))
        temporary=output.with_name(output.name+'.partial')
        if temporary.exists(): raise ValueError('Partial output already exists')
        try:
            with zipfile.ZipFile(temporary,'w',zipfile.ZIP_DEFLATED) as result:
                for entry in archive.infolist():
                    result.writestr(entry,patched if entry.filename==binary else archive.read(entry.filename))
                entry=zipfile.ZipInfo(target); entry.external_attr=0o100755<<16
                result.writestr(entry,library)
            with zipfile.ZipFile(temporary) as check:
                if check.testzip(): raise ValueError('Output integrity failure')
            temporary.replace(output)
        except Exception:
            temporary.unlink(missing_ok=True); raise
    print('Created unsigned IPA:',output,'bundle:',bundle)

if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('source'); p.add_argument('addon'); p.add_argument('output')
    p.add_argument('--allow-original',action='store_true',help='Same bundle ID may replace installed WhatsApp Business. No data migration is performed.')
    a=p.parse_args(); package(a.source,a.addon,a.output,a.allow_original)
