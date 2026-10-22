import struct, sys
data = open(sys.argv[1], 'rb').read()
def walk(off, end, depth):
    while off + 8 <= end:
        size, typ = struct.unpack('>I4s', data[off:off+8]); hdr = 8
        if size == 1: size = struct.unpack('>Q', data[off+8:off+16])[0]; hdr = 16
        if size == 0: size = end - off
        t = typ.decode('latin1'); body = data[off+hdr:off+size]
        info = ''
        if t in ('mvhd', 'mdhd'):
            v = body[0]
            ts, dur = struct.unpack('>IQ', body[20:32]) if v == 1 else struct.unpack('>II', body[12:20])
            info = f'v{v} timescale={ts} duration={dur} -> {dur/ts:.3f}s'
        elif t == 'mehd':
            v = body[0]; dur = struct.unpack('>Q' if v == 1 else '>I', body[4:12] if v == 1 else body[4:8])[0]
            info = f'fragment_duration={dur}'
        elif t == 'sidx':
            v = body[0]; ts = struct.unpack('>I', body[8:12])[0]
            n = struct.unpack('>H', body[(30 if v else 22):(32 if v else 24)])[0]
            base = 32 if v else 24; tot = 0
            for i in range(n):
                tot += struct.unpack('>I', body[base+4+12*i:base+8+12*i])[0]
            info = f'timescale={ts} refs={n} total={tot} -> {tot/ts:.3f}s'
        elif t == 'elst':
            info = body[:24].hex()
        elif t == 'stsd':
            info = ''
        if depth < 4 and (t in ('moov','trak','mdia','minf','stbl','mvex','edts') or info or depth == 0):
            print('  '*depth + f'{t} size={size} {info}')
        if t in ('moov','trak','mdia','minf','stbl','mvex','edts'):
            walk(off+hdr, off+size, depth+1)
        off += size
walk(0, len(data), 0)
