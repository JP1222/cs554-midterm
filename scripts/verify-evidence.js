'use strict';
const fs=require('node:fs');const path=require('node:path');const assert=require('node:assert/strict');
const dir=path.resolve(__dirname,'../evidence');
const data=f=>JSON.parse(fs.readFileSync(path.join(dir,f),'utf8'));
const names=['02-baseline','03-before-delete','03-after-replacement','04-selector-baseline','04-selector-failure','04-selector-recovery','05-readiness-baseline','05-readiness-failure','05-readiness-recovery'];
const summary={verifiedAt:new Date().toISOString(),phases:{}};
for(const n of names){const pods=data(n+'-pods.json').items;const endpoints=data(n+'-endpointslices.json').items.flatMap(x=>x.endpoints||[]);summary.phases[n]={pods:pods.map(x=>({name:x.metadata.name,uid:x.metadata.uid,phase:x.status.phase,ready:x.status.containerStatuses[0].ready,restarts:x.status.containerStatuses[0].restartCount,containerId:x.status.containerStatuses[0].containerID})),readyEndpoints:endpoints.filter(x=>x.conditions.ready).length};assert.equal(pods.length,2);assert.equal(summary.phases[n].readyEndpoints,n==='04-selector-failure'?0:n==='05-readiness-failure'?1:2);}
const before=summary.phases['03-before-delete'].pods.map(x=>x.uid);const after=summary.phases['03-after-replacement'].pods.map(x=>x.uid);assert.equal(before.filter(x=>after.includes(x)).length,1);
const baseline=summary.phases['05-readiness-baseline'].pods;
for(const phase of ['05-readiness-failure','05-readiness-recovery'])for(const p of summary.phases[phase].pods){const b=baseline.find(x=>x.uid===p.uid);assert.ok(b);assert.equal(p.containerId,b.containerId);assert.equal(p.restarts,b.restarts);assert.equal(p.phase,'Running');}
assert.equal(summary.phases['05-readiness-failure'].pods.filter(p=>p.ready).length,1);assert.equal(summary.phases['05-readiness-recovery'].pods.filter(p=>p.ready).length,2);
const build=fs.readFileSync(path.join(dir,'01-compose.txt'),'utf8');const config=build.match(/exporting config (sha256:[0-9a-f]{64})/)[1];assert.ok(data('02-baseline-pods.json').items.every(p=>p.status.containerStatuses[0].imageID===config));summary.imageConfigDigest=config;summary.assertions='PASS: all 9 phases, Pod replacement, unchanged readiness process/container IDs, 2->1->2 ready endpoints, matching application image config';fs.writeFileSync(path.join(dir,'verification-summary.json'),JSON.stringify(summary,null,2)+'\n');console.log(summary.assertions);
