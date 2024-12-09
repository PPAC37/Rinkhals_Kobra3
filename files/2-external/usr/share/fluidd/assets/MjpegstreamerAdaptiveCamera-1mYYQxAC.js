var u=Object.defineProperty;var l=(a,t,e)=>t in a?u(a,t,{enumerable:!0,configurable:!0,writable:!0,value:e}):a[t]=e;var r=(a,t,e)=>l(a,typeof t!="symbol"?t+"":t,e);import{m as g,C as p,j as d,R as f,k as S}from"./index-B6qYYCY3.js";var _=Object.defineProperty,T=Object.getOwnPropertyDescriptor,c=(a,t,e,m)=>{for(var s=m>1?void 0:m?T(t,e):t,i=a.length-1,o;i>=0;i--)(o=a[i])&&(s=(m?o(t,e,s):o(s))||s);return m&&s&&_(t,e,s),s};let n=class extends g(p){constructor(){super(...arguments);r(this,"cameraImage");r(this,"cameraImageSource","");r(this,"cameraImageSourceUrl",null);r(this,"requestStartTime",performance.now());r(this,"startTime",performance.now());r(this,"time",0);r(this,"requestTime",0);r(this,"timeSmoothing",.6);r(this,"requestTimeSmoothing",.1)}handleImageLoad(){const e=!document.hasFocus()&&this.camera.target_fps_idle||this.camera.target_fps||10,m=performance.now(),s=m-this.startTime;this.time=this.time*this.timeSmoothing+s*(1-this.timeSmoothing),this.startTime=m;const i=1e3/e,o=performance.now()-this.requestStartTime;this.requestTime=this.requestTime*this.requestTimeSmoothing+o*(1-this.requestTimeSmoothing);const h=Math.max(0,i-this.requestTime);this.$nextTick(()=>{setTimeout(this.handleRefresh,h)})}handleRefresh(){if(document.hidden)this.stopPlayback();else{const e=Math.round(1e3/this.time).toString().padStart(2,"0");this.$emit("update:frames-per-second",e),this.$nextTick(()=>this.updateCameraImageSource())}}updateCameraImageSource(){const e=this.cameraImageSourceUrl;e&&(e.searchParams.set("cacheBust",Date.now().toString()),this.requestStartTime=performance.now(),this.cameraImageSource=e.toString())}startPlayback(){this.cameraImageSourceUrl=this.buildAbsoluteUrl(this.camera.snapshot_url||""),this.updateCameraImageSource();const e=this.buildAbsoluteUrl(this.camera.stream_url||"");e.searchParams.set("cacheBust",Date.now().toString()),this.$emit("update:raw-camera-url",e.toString())}stopPlayback(){this.cameraImageSourceUrl=null,this.cameraImageSource="",this.cameraImage.src=""}};c([f("streamingElement")],n.prototype,"cameraImage",2);n=c([d({})],n);var I=function(){var t=this,e=t._self._c;return t._self._setupProxy,e("img",{ref:"streamingElement",style:t.cameraStyle,attrs:{src:t.cameraImageSource,crossorigin:t.crossorigin},on:{load:t.handleImageLoad}})},v=[],q=S(n,I,v,!1,null,null);const b=q.exports;export{b as default};