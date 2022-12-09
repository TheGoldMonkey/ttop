import procfs
import marshal
import zippy
import streams

const blog = "/tmp/1.blog"

proc hist*(ii: int): (FullInfoRef, int) =
  if ii == 0:
    result[0] = fullInfo()
  let s = newFileStream(blog)
  if s == nil:
    return
  defer: s.close()

  var buf = ""

  result[1] = 0
  while not s.atEnd():
    let sz = s.readUInt32().int
    buf = s.readStr(sz)
    discard s.readUInt32()
    if ii == result[1]+1:
      new(result[0])
      result[0][] = to[FullInfo](uncompress(buf))
    inc result[1]

  if ii == -1:
    if result[1] > 0:
      new(result[0])
      result[0][] = to[FullInfo](uncompress(buf))
    else:
      result[0] = fullInfo()

proc save*() =
  var (prev, _) = hist(-1)
  let info = if prev == nil: fullInfo() else: fullInfo(prev)
  let buf = compress($$info[])
  let s = newFileStream(blog, fmAppend)
  defer: s.close()
  s.write buf.len.uint32
  s.write buf
  s.write buf.len.uint32

when isMainModule:
  var (prev, _) = hist(-1)
  let info = if prev == nil: fullInfo() else: fullInfo(prev)
  import tables
  import strutils
  for k, v in info.pidsInfo:
    if "save" in v.name:
      echo k, ": ", v