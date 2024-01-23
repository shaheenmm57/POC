import { LightningElement, api, wire } from 'lwc';
import getEmbeddingDataForReport from '@salesforce/apex/PowerBiEmbedManager.getEmbeddingDataForReport';
import powerbijs from '@salesforce/resourceUrl/powerbijs';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';


export default class PowerBiReport extends LightningElement {

  @api Username ='';
  @api WorkspaceId ='';
  @api ReportId ='';
  @api Datasets ='';
  @api PageName ='';
  @api Visual ='';
  
    
  @wire(getEmbeddingDataForReport,{
    WorkspaceId: "$WorkspaceId",
    ReportId: "$ReportId",
    Username : "$Username",
    Datasets : "$Datasets",
    PageName : "$PageName",
    Visual : "$Visual"
  }) report;

//   @api loadedResolve ;
// @api reportLoaded = new Promise((res, rej) => { loadedResolve = res; });
//  @api renderedResolve ;
// @api reportRendered = new Promise((res, rej) => { renderedResolve = res; });

embedPowerBIReport() {
}
    renderedCallback() {
      var report=this.embedPowerBIReport();
      setTimeout(()=>{
      console.log(report, 'after embed');

// Insert here the code you want to run after the report is rendered

// Retrieve the page collection, and then set the second page to be active.
try {
  console.log('after embed');
    const pages =  report.getPages();
    console.log('after getpages');

     pages[0].setActive();
    console.log("Active page was set to: \"" + pages[0].displayName + "\"");
}
catch (errors) {
    console.log(errors);
}
// Retrieve the page collection and get the visuals for the active page.
try {
    const pages =  report.getPages();
    // Retrieve the page that contain the visual. For the sample report it will be the active page
    let page = pages.filter(function (page) {
        return page.isActive
    })[0];

    const visuals =  page.getVisuals();
    console.log(
        visuals.map(function (visual) {
            return {
                name: visual.name,
                type: visual.type,
                title: visual.title,
                layout: visual.layout
            };
        }));
}
catch (errors) {
    console.log(errors);
}
      },10000);


    }
    embedPowerBIReport() {

      console.log('renderedCallback exectuting');
  
      Promise.all([ loadScript(this, powerbijs ) ]).then(async() => { 
       
  
        console.log('renderedCallback 2');
        console.log("this.report", this.report);
  
          if(this.report.data){
  
            if(this.report.data.embedUrl && this.report.data.embedToken){
              var reportContainer = this.template.querySelector('[data-id="embed-container"');
  
              var reportId = this.report.data.reportId;
              var embedUrl = this.report.data.embedUrl;
              var token = this.report.data.embedToken;
              var visual = this.report.data.visualName;
              var embedType = this.report.data.type;
              var pageName = this.report.data.pageName;

            
              var config;
              if(embedType=='visual'){
                config= {
                  type: embedType,
                  id: reportId,
                  embedUrl: embedUrl,
                  accessToken: token,
                  tokenType: 1,
                  pageName: pageName,
                  visualName: visual,
                  settings: {
                    bars: {
                        statusBar: {
                            visible: true
                        }
                    },
                    visualSettings: {
                        visualHeaders: [
                          {
                            settings: {
                                visible: false
                            },
                            selector: {
                                $schema: "http://powerbi.com/product/schema#visualSelector",
                                visualName: "75b84323a30760052e3e"
                            }
                        }
                        ]
                    }
                }
                };
              } 
              if(embedType=='report'){
                console.log('inside report section');
                console.log(reportId,embedType,pageName);
                config = {
                type: embedType,
                id: reportId,
                embedUrl: embedUrl,
                accessToken: token,
                tokenType: 1,
                settings: {
                  panes: {
                    filters: { expanded: false, visible: true },
                    pageNavigation: { visible: false }
                  }
                }
              };
              }
          console.log(config, 'config');
              // Embed the report and display it within the div container.
              var reports={};
              reports = await powerbi.embed(reportContainer, config) ;
              let pages = await reports.getPages();
              console.log(pages,'pages');
              this.reportLoaded;

              // Insert here the code you want to run after the report is loaded
              
               this.reportRendered;
              console.log('reports loaded');
              // report.off removes all event handlers for a specific event
              reports.off("loaded");
             
              console.log('reports off loaded');
  
      // report.on will add an event handler
      // reports.on("loaded", function () {
      //     loadedResolve();
      //     reports.off("loaded");
      // });
      
      // // report.off removes all event handlers for a specific event
      // reports.off("error");
  
      // reports.on("error", function (event) {
      //     console.log(event.detail);
      // });
  
      // // report.off removes all event handlers for a specific event
      // reports.off("rendered");
  
      // // report.on will add an event handler
      // reports.on("rendered", function () {
      //     renderedResolve();
      //     reports.off("rendered");
      // });
      // console.log('reports rendered loaded');
      setTimeout(()=>{
        console.log(reports,'reports');
      console.log(reports.getPages(),'reportsPages');
      },100000);
      
      
  
            return reports;
    
  
            }
            else {
              console.log('no embedUrl or embedToken');
            }
              
            }
            else{
                console.log('no report.data yet');
            }
     
  
      });

     
    }

}