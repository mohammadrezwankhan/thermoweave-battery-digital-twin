/* Bounded documentation fixture check; does not execute DOM or native MATLAB. */
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const html = fs.readFileSync(path.join(root, 'docs/index.html'), 'utf8');
const config = JSON.parse(fs.readFileSync(path.join(root, 'docs/lesson-config.json'), 'utf8'));
const scripts = [...html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script\s*>/gi)];
const json = scripts.find(m => /\bid=["']lab-config["']/.test(m[1]));
assert.ok(json, 'Embedded lab configuration is required');
assert.deepEqual(JSON.parse(json[2]), config, 'Embedded and canonical configurations differ');
const pure = scripts.filter(m => m[2].includes('Offline teaching models.'));
assert.equal(pure.length, 1, 'Exactly one reviewed pure model unit is required');
const digest = text => crypto.createHash('sha256').update(text).digest('hex');
assert.equal(digest(pure[0][2]), '591ebcfbbcec9daca64f2ba382611609d54ceeba89a8e34ba46f1fa744558042', 'Pure model changed; inspect it and update the documented fixture contract');
const sandbox = {module: {exports: {}}};
vm.runInNewContext(pure[0][2], sandbox, {timeout: 2000, filename: 'reviewed-pure-model.js'});
const api = sandbox.module.exports;
assert.equal(config.model.kind, 'thermal');
const kind = config.model.kind, spec = api.getModelSpec(kind);
const defaults = api.resolveParameters(kind, {...Object.fromEntries(config.model.parameters.map(p => [p.key,p.default])), ...(config.model.defaults || {})});
const checkpoints = [];
for (const lesson of config.modules) {
  const params = api.resolveParameters(kind, {...defaults, ...(lesson.preset || {})});
  for (const check of lesson.checkpoints) {
    const values = api.evaluateModel(kind,params,check.atTime);
    const result = api.checkCheckpoint(check,values);
    assert.equal(result.status, 'pass', lesson.id+': '+check.label);
    checkpoints.push({module:lesson.id,metric:check.metric,time_min:check.atTime,expected:check.expected,tolerance:check.tolerance,observed:values[check.metric],result:'PASS'});
  }
}
assert.equal(checkpoints.length, 8);
const baseline = api.evaluateModel(kind,defaults,10);
const rise = 600/30*(1-Math.exp(-30*600/12000));
assert.ok(Math.abs(baseline.temperatureC-(20+rise))<1e-12);
assert.ok(Math.abs(baseline.storedEnergyKJ-12000*rise/1000)<1e-12);
assert.ok(Math.abs(baseline.residualW-(600-30*rise))<1e-12);
assert.equal(api.resolveParameters(kind,{heatW:-100}).heatW,100);
assert.equal(api.resolveParameters(kind,{heatW:99999}).heatW,3000);
assert.equal(api.resolveParameters(kind,{heatW:NaN}).heatW,1200);
assert.equal(api.resolveParameters(kind,{heatW:601}).heatW,601);
assert.equal(api.evaluateModel(kind,defaults,-1).temperatureC,20);
assert.equal(api.evaluateModel(kind,defaults,NaN).temperatureC,20);
assert.equal(api.evaluateModel(kind,defaults,90).temperatureC,api.evaluateModel(kind,defaults,60).temperatureC);
assert.throws(()=>api.getModelSpec('unsupported-kind'));
assert.equal(api.checkCheckpoint({metric:'x',operator:'==',expected:1,tolerance:.1},{x:1.05}).status,'pass');
assert.equal(api.checkCheckpoint({metric:'x',operator:'>',expected:1,tolerance:10},{x:1}).status,'fail');
assert.equal(api.checkCheckpoint({metric:'x',operator:'?',expected:1},{x:1}).status,'invalid');
assert.equal(api.checkCheckpoint({metric:'missing',expected:1},{}).status,'invalid');
console.log(JSON.stringify({result:'PASS',node:process.version,pure_model_sha256:digest(pure[0][2]),lesson_config_sha256:digest(fs.readFileSync(path.join(root,'docs/lesson-config.json'))),configured_kind:kind,checkpoints,bounded_contract_probes:15,baseline,limits:['Only reviewed pure scalar JavaScript arithmetic and fixture semantics executed','No DOM, canvas, downloads, clipboard, storage, native MATLAB, physical validation or deployment execution']},null,2));
