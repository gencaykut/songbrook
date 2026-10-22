import struct, sys
d = bytearray(open(sys.argv[1], 'rb').read())
def find(t, start=0):
    return d.find(t, start) - 4
m = find(b'mvhd'); struct.pack_into('>I', d, m + 8 + 16, 0)        # mvhd v0 duration
h = find(b'mdhd'); struct.pack_into('>I', d, h + 8 + 16, 0)        # mdhd v0 duration
e = find(b'elst'); struct.pack_into('>I', d, e + 8 + 8, 0)         # elst segment_duration
open(sys.argv[2], 'wb').write(d)
