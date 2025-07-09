sub init()
    m.top.functionName = "run"
end sub

function run() as void
    url = m.top.url
    if url = invalid or Len(url) = 0 then
        LogError("HostTask: no URL specified")
        return
    end if

    cached = CacheGet(url)
    if cached <> invalid then
        Log("HostTask cache hit " + url)
        m.top.message = cached
        return
    end if

    Log("HostTask requesting " + url)
    xfer = CreateObject("roUrlTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.AddHeader("User-Agent", "Mozilla/5.0")
    xfer.SetUrl(url)
    html = xfer.GetToString()
    if html = invalid then
        LogError("HostTask failed to load " + url)
    else
        Log("HostTask received response")
        CacheSet(url, html)
    end if
    m.top.message = html
end function
