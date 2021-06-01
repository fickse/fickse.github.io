## generate fickse.github.io

library(readxl)

generate_page <- function(pagename, title, subtitle = '', headerimage = 'images/Banner.png'){

    header <- readLines('html/basic.html')
    page <- gsub('<!--PAGENAME-->', pagename, header)
    navbar <- paste(readLines('html/navbar.html'), collapse = '\n')
    navbar <- gsub('<!--HEADERIMAGE-->', headerimage, navbar)
    navbar <- gsub('<!--TITLE-->', title, navbar)
    page <- gsub('<!--NAVBAR-->', navbar, page)
    return(page)
}


##################
## make index page

idx = generate_page('Steve Fick', 'STEVE FICK', 'Geospatial Data Scientist', 'images/background.jpg')


## index page content

idx_content = '
<div class="w3-content w3-padding-large w3-margin-top" id="portfolio">
    <div class="main">
        <img class="w3-image" src="images/steve2bwborder.JPG" alt="Me" width="150" height="60"><br>
             I develop tools and datasets for evidence-based decision making. My areas of specialization include environmental modeling, data science, spatial ecology, and restoration ecology.
            <br><br><a href="https://scholar.google.com/citations?user=Y4h2OOoAAAAJ&hl=en">
                <i class="ai ai-google-scholar ai-1x"></i></a>   
                <a href="https://github.com/fickse"<i class="fa fa-github fa-4"></i></a> <a href="https://fickse.wordpress.com/">blog</a>    
                <a href="https://www.linkedin.com/in/steve-fick-334652195/"> linkedin </a>

                <a href="https://orcid.org/0000-0002-3548-6966"><i class="ai ai-orcid ai-1x"></i></a></div>

    </div>

</div>

'

idx = gsub('<!--CONTENT-->', idx_content, idx)


cat(idx, file = 'index.html', sep = '\n')


########################
## Make Publications page

pubs = generate_page('Publications', 'PUBLICATIONS')

## generate publications content
pp = as.data.frame(read_excel('RESUME.xlsx', sheet = 3))

strings <- ''
pp <- pp[rev(order(pp$Year)),]
for ( i in 1:nrow(pp)){

    f <- file.path('files',pp$pdf[i])
    string <- paste0('<li><a href=', f, '.pdf>', pp$Citation[i], '</a>')
    strings <- c(strings, string)
}


prefix = '
<div class="w3-content w3-padding-large w3-margin-top" id="portfolio">
<div class="main">
    <div style="padding-left:1.5em;text-indent:-2.5em;font-size:15px;color:#af5454">
'
suffix = '</div>
</div>
</div>
'
strings <- paste(strings, collapse = '\n')
strings <- paste0(prefix, strings, suffix)
pubs <- gsub('<!--CONTENT-->', strings, pubs)
cat( pubs, file = 'publications.html', sep = '\n')


###########################
## Make CV page

cv <- generate_page('CV', 'Curriculum Vitae')

cv_content = '
<div class="w3-content w3-padding-large w3-margin-top" id="portfolio">

  <!-- Images (Portfolio) -->
  <embed src="assets/cv.pdf" width="800px" height="2100px" />

</div>
'

cv <- gsub('<!--CONTENT-->', cv_content, cv)
cv <- paste(cv, collapse = '\n')
cat( cv, file = 'cv.html', sep = '\n')


###########################
## Make Projects Page
proj <- generate_page('projects', 'PROJECTS')

proj_content <- '
<div class="w3-content w3-padding-large w3-margin-top" id="portfolio">

  <!-- Images (Portfolio) -->
<div class="main">
<table>
  <tr>
   <td>
   <img src="images/thumb.PNG" alt="thumb" style="max-width:160px" class="w3-image" /> <br>
   </td>
   
   <td>
   Using geospatial data and historical records to evaluate conservation and restoration practice effectiveness across the Upper Colorado River Basin
   </td>
   </tr>
   
  <tr>   
    <td>
      <img src="images/thumb_ic.jpg" alt="thumb" style="max-width:160px" />
    </td>
    
    <td>
      Working with <a href="https://www.zekebaker.com/projects">social scientists</a> to study how <a href="https://sciencemoab.org/climbersplace/">rock climbers at Indian Creek</a> (Bears Ears) evaluate their cultural and ecological impacts in the context of land-use conflict, new technologies and the burgeoning growth of the outdoor recreation industry.
    </td>
  </tr>

  <tr>
    <td>
        <img src="images/704_2016_b.jpg" alt="thumb" style="max-width:160px" />
    </td>
    <td>
      Testing <a href="https://www.usgs.gov/centers/sbsc/science/new-approaches-restoring-colorado-plateau-grasslands?qt-science_center_objects=0#qt-science_center_objects">novel restoration practices</a> for degraded arid lands with field experiments.</li>
    </td>
  </tr>

  <tr>
    <td>
      <img src="images/trase.PNG" alt="thumb" style="max-width:160px" />
    </td>
    <td>
      Linking consumers, exporters, and production geographies in the global trade of forest-risk commodities with a <a href="https://www.trase.earth">supply-chain traceability tool</a> (trase).
    </td>
  </tr>
  
  <tr>
    <td>
      <img src="images/WC2.PNG" alt="thumb" style="max-width:160px" />
    </td>
    <td>
      <a href="http://worldclim.org/version2">WorldClim 2</a>: A global climatology dataset updated with data from new stations and satellite archives
    </td>
  </tr>
  </table>
  

  </div>

</div>

  

</div>

  </div>

</div>


<!-- End page content -->
</div>
'

proj <- gsub('<!--CONTENT-->', proj_content, proj)
proj <- paste(proj, collapse = '\n')
cat( proj, file = 'projects.html', sep = '\n')


###########################
## Make Photography page

photo <- generate_page('photography', 'PHOTOGRAPHY')
photo_content <- '
<br>
<img src="images/colorado.JPG" class="photo"/>
<img src="images/tilden.JPG"  class="photo"/>
<img src="images/balanced.jpg"  class="photo"/>
<img src="images/sierra.png"  class="photo"/>

'
photo <- gsub('<!--CONTENT-->', photo_content, photo)
photo <- gsub('<body>', '<body style="background-color:black;">', photo)

photo <- paste(photo, collapse = '\n')
cat( photo, file = 'photography.html', sep = '\n')
