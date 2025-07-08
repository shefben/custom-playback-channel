sub init()
    m.top.functionName = "run"
end sub

function run() as void
    query = m.top.query
    if query = invalid or Len(query) = 0 return
    base = m.top.baseUrl
    transfer = CreateObject("roUrlTransfer")
    encoded = transfer.Escape(query)
    url = base + "/index.php?menu=search&query=" + encoded
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.AddHeader("User-Agent", "Mozilla/5.0")
    transfer.SetUrl(url)
    html = transfer.GetToString()
    m.top.message = html
end function
