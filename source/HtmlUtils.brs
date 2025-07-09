'Utility functions for HTML parsing
'
'ParseSearchResults returns an array of objects with { title, imgUrl, pageUrl }
'Any malformed figure blocks will be logged via print statements

function ParseSearchResults(html as String, baseUrl as String) as Object
    results = []
    if html = invalid return results

    figureRegex = CreateObject("roRegex", "<figure[^>]*class\\s*=\\s*\"figured\"[^>]*>(.*?)</figure>", "ims")
    hrefRegex = CreateObject("roRegex", "<a[^>]+href=\"([^\"]+)\"", "ims")
    imgRegex = CreateObject("roRegex", "<img[^>]+(?:data-src|src)=\"([^\"]+)\"", "ims")
    titleRegex = CreateObject("roRegex", "<(?:div|figcaption)[^>]*class=\"title[^"]*\"[^>]*>([^<]+)<", "ims")

    figures = figureRegex.MatchAll(html)
    for each item in figures
        block = item[1]
        hrefMatch = hrefRegex.Match(block)
        imgMatch = imgRegex.Match(block)
        titleMatch = titleRegex.Match(block)
        if hrefMatch.Count() = 0 or imgMatch.Count() = 0 or titleMatch.Count() = 0
            print "Malformed figure block:" + Chr(10) + block
        else
            path = hrefMatch[1]
            if Left(path,1) = "/" then path = baseUrl + path
            result = {
                title: titleMatch[1],
                imgUrl: imgMatch[1],
                pageUrl: path
            }
            results.Push(result)
        end if
    end for

    return results
end function

