function Log(msg as String) as void
    if msg = invalid then msg = "invalid"
    print "[LOG] " + msg
end function

'Print and store an error message so it can be reviewed later'
function LogError(msg as String) as void
    if msg = invalid then msg = "invalid"
    g = GetGlobalAA()
    if g.DoesExist("errorLogs") = false then
        g.errorLogs = []
    end if
    g.errorLogs.Push(msg)
    if g.errorLogs.Count() > 50 then
        g.errorLogs.Shift()
    end if
    print "[ERR] " + msg
end function

'Return stored error messages'
function GetErrorLogs() as object
    g = GetGlobalAA()
    if g.DoesExist("errorLogs") then
        return g.errorLogs
    else
        return []
    end if
end function

'Cache helpers for HTTP requests'
function CacheSet(url as String, data as dynamic) as void
    g = GetGlobalAA()
    if g.DoesExist("httpCache") = false then
        g.httpCache = {}
    end if
    g.httpCache[url] = data
end function

function CacheGet(url as String) as dynamic
    g = GetGlobalAA()
    if g.DoesExist("httpCache") and g.httpCache.DoesExist(url) then
        return g.httpCache[url]
    else
        return invalid
    end if
end function
