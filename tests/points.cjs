const vm=require('node:vm'),fs=require('node:fs'),assert=require('node:assert/strict');
const el={innerHTML:'',classList:{toggle(){}},onclick:null};const context=vm.createContext({console,Date,Set,Number,String,JSON,Math,crypto:require('node:crypto').webcrypto,localStorage:{getItem(){return null},setItem(){}},document:{querySelector(){return el},querySelectorAll(){return []}},setTimeout});vm.runInContext(fs.readFileSync('dist/app.js','utf8'),context);
vm.runInContext(`
if(monday('2026-11-29')!=='2026-11-23'||monday('2026-11-30')!=='2026-11-30')throw Error('Week rollover');
state=empty();date='2026-11-28';if(steps('morning').length!==3||steps('gear').length!==1)throw Error('Weekend checklist');
date='2026-11-24';if(steps('morning').length!==5||steps('gear').length!==4||steps('night').length!==5)throw Error('Weekday checklist');
for(let i=0;i<20;i++){let d=shift('2026-10-01',i);state.days[d]={...day(d),awards:missions.map(m=>m[0])}};
if(bank()!==100)throw Error('Earned point balance');
state.spent.push({cost:100,label:'Local',date:'2026-11-24'});if(bank()!==0)throw Error('Redemption balance');
if(weekly('2026-10-05')!==35)throw Error('Weekly count');
state.claims['2026-10-05']=true;if(bank()!==0)throw Error('Target must be free');
validate(state);let bad=JSON.parse(JSON.stringify(state));bad.spent.push({cost:300,label:'Invalid'});let caught=false;try{validate(bad)}catch{caught=true}if(!caught)throw Error('Overspent backup accepted');
`,context);console.log('Passed: week rollover, weekday/weekend checklists, points, redemption, free Target rewards, backup validation.');
