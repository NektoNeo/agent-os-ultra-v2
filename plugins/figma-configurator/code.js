figma.on('run', async ({ command }) => {
  if (command === 'render') { await renderFromSpec(); }
  else { figma.showUI(__html__, { width: 420, height: 520 }); }
});
async function fetchSpec(url) {
  try { const res = await fetch(url); if (!res.ok) throw new Error('HTTP '+res.status); return await res.json(); }
  catch (e) { figma.notify('Failed to fetch spec: '+e.message); return null; }
}
async function renderFromSpec() {
  const url = await figma.clientStorage.getAsync('spec_url');
  if (!url) { figma.notify('Open UI and set spec URL first'); figma.showUI(__html__, { width: 420, height: 520 }); return; }
  const spec = await fetchSpec(url); if (!spec) return;
  await build(spec); figma.notify('Rendered from spec');
}
async function build(spec) {
  const frames = spec.frames || [];
  for (const f of frames) {
    const frame = figma.createFrame();
    frame.name = f.name || 'Frame';
    frame.resizeWithoutConstraints(f.w || 1440, f.h || 1024);
    const nodes = f.nodes || [];
    for (const n of nodes) {
      if (n.type === 'text') {
        const t = figma.createText(); t.characters = n.text || '';
        try { await figma.loadFontAsync({ family: 'Inter', style: 'Regular' }); } catch(e){}
        if (n.fontSize) t.fontSize = n.fontSize; t.x = n.x||0; t.y = n.y||0; frame.appendChild(t);
      } else if (n.type === 'rect') {
        const r = figma.createRectangle(); r.resize(n.w||100, n.h||100);
        r.x = n.x||0; r.y = n.y||0;
        if (n.fill) { const c = hexToRGB(n.fill); r.fills = [{ type: 'SOLID', color: c }]; }
        if (n.corner) r.cornerRadius = n.corner; frame.appendChild(r);
      }
    }
    figma.currentPage.appendChild(frame);
  }
}
function hexToRGB(hex){const m=/^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex||'#999');return{r:parseInt(m[1],16)/255,g:parseInt(m[2],16)/255,b:parseInt(m[3],16)/255};}
figma.ui.onmessage = async (msg) => {
  if (msg.type === 'get-url') { const url = await figma.clientStorage.getAsync('spec_url'); figma.ui.postMessage({ type:'set-url', value:url }); }
  else if (msg.type === 'save-url') { await figma.clientStorage.setAsync('spec_url', msg.url||''); figma.notify('Saved.'); }
  else if (msg.type === 'render') { if (msg.url) await figma.clientStorage.setAsync('spec_url', msg.url); await renderFromSpec(); }
};
