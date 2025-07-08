sub init()
    m.top.functionName = "run"
end sub

function run() as void
    url = m.top.url
    if url = invalid or Len(url) = 0 return
    xfer = CreateObject("roUrlTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.AddHeader("User-Agent", "Mozilla/5.0")
    xfer.SetUrl(url)
    html = xfer.GetToString()
    m.top.message = html
end function
