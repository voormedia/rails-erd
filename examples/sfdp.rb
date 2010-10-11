Dir["output/*.dot"].each do |file|
  `sfdp -Tpdf -Gmclimit=5 -GK=1 -Grepulsiveforce=40 -Gsplines=true -Goverlap=false -ooutput/#{File.basename(file, ".dot")}-sfdp.pdf #{file}`
end
