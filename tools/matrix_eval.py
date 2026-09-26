import json,os,re,math,collections,sys,glob
import pathlib
R=os.environ.get('RESULTS_DIR') or str(pathlib.Path(__file__).resolve().parent.parent/'results')+'/'
MODELS=[('glm-5.3-flash','glm-5.3-flash_cloud'),('deepseek-v4.1-flash','deepseek-v4.1-flash_cloud')]
MARK=re.compile(r'Referenz \(laut Regelwerk\)|set_waza_grade_pass|Beispiel fuer eine RICHTIGE Antwort|judge_[a-z0-9_]+_00[0-9]')
def wilson(k,n,z=1.96):
    if n==0: return (0,0)
    p=k/n; d=1+z*z/n; c=p+z*z/(2*n); h=z*math.sqrt(p*(1-p)/n+z*z/(4*n*n)); return ((c-h)/d,(c+h)/d)
def load(fn):
    p=R+fn
    if not os.path.exists(p): return None
    d=json.load(open(p,encoding='utf-8')); out={}
    for t in d['tasks']:
        runs=[]
        for r in t['runs']:
            calls=(r.get('session_digest') or {}).get('tool_calls') or []
            v=r.get('validations') or {}; j=[x.get('passed') for k,x in v.items() if k.startswith('judge_') and isinstance(x,dict)]
            runs.append(dict(ok=r['status']=='passed',err=bool(r.get('error_msg')),skill=any(c['name']=='skill' for c in calls),calls=len(calls),dur=(r.get('duration_ms') or 0)/1000,
                judge=(all(j) if j else None),
                leak=any(MARK.search(json.dumps(c.get('result') or {},ensure_ascii=False)) for c in calls if c['name']!='skill'),
                read=any('regelwerk' in json.dumps(c.get('arguments') or {}).lower() and c['name'] in('view','grep','glob','bash') for c in calls)))
        out[t['test_id']]=runs
    return out
cells={}
for short,fn in MODELS:
    cells[(short,'skill')]=load(f'ollama-{fn}-mx-skill.json'); cells[(short,'base')]=load(f'ollama-{fn}-baseline-mx.json')
def agg(c):
    runs=[r for rs in c.values() for r in rs]; k=sum(r['ok'] for r in runs); n=len(runs); lo,hi=wilson(k,n)
    return k,n,lo,hi,sum(r['err'] for r in runs),sum(r['leak'] for r in runs),sum(r['skill'] for r in runs),sum(r['dur'] for r in runs)/max(1,n),sum(r['calls'] for r in runs)/max(1,n)
print("=== Trefferquote je Zelle (Einzelläufe; 95%-Wilson-Intervall) ===")
print(f"{'Modell':22}{'Bedingung':18}{'bestanden':>16}{'Rate':>7}{'95%-CI':>16}  Fehler Lecks Skill-geladen  Ø Dauer  Ø Aufrufe")
for (m,cond),c in cells.items():
    if c is None: print(f"{m:22}{'mit Skill' if cond=='skill' else 'ohne Regelwerk':18}  (noch nicht vorhanden)"); continue
    k,n,lo,hi,e,lk,sk,du,ca=agg(c); print(f"{m:22}{'mit Skill' if cond=='skill' else 'ohne Regelwerk':18}{k:>8}/{n:<7}{100*k/n:6.1f}%  [{100*lo:4.1f}–{100*hi:4.1f}]  {e:5} {lk:5} {sk:8}/{n:<4} {du:6.0f}s {ca:7.1f}")
print("\n=== Mehrwert des Regelwerks (mit Skill − ohne), je Modell ===")
for m,_ in MODELS:
    a,b=cells[(m,'skill')],cells[(m,'base')]
    if a is None or b is None: continue
    ids=[i for i in a if i in b]; pa=[sum(r['ok'] for r in a[i])/len(a[i]) for i in ids]; pb=[sum(r['ok'] for r in b[i])/len(b[i]) for i in ids]
    better=sum(x>y for x,y in zip(pa,pb)); worse=sum(x<y for x,y in zip(pa,pb)); eq=len(ids)-better-worse
    print(f"{m:22} mit {100*sum(pa)/len(ids):5.1f}% | ohne {100*sum(pb)/len(ids):5.1f}% | Differenz {100*(sum(pa)-sum(pb))/len(ids):+5.1f} Punkte | Tasks besser/gleich/schlechter mit Skill: {better}/{eq}/{worse}")
print("\n=== Modellvergleich (Deepseek − GLM), jeweils Einzelläufe ===")
for cond,lbl in (('skill','mit Skill'),('base','ohne Regelwerk')):
    a,b=cells[('glm-5.3-flash',cond)],cells[('deepseek-v4.1-flash',cond)]
    if a is None or b is None: continue
    ids=[i for i in a if i in b]; pa=sum(sum(r['ok'] for r in a[i])/len(a[i]) for i in ids)/len(ids); pb=sum(sum(r['ok'] for r in b[i])/len(b[i]) for i in ids)/len(ids)
    print(f"{lbl:16} GLM {100*pa:5.1f}% | Deepseek {100*pb:5.1f}% | Differenz {100*(pb-pa):+5.1f} Punkte ({len(ids)} Tasks)")
print("\n=== Streuung: Tasks mit gemischten Trials (mind. 1 bestanden und 1 nicht) ===")
for (m,cond),c in cells.items():
    if c is None: continue
    mixed=[i for i,rs in c.items() if 0<sum(r['ok'] for r in rs)<len(rs)]
    print(f"{m:22}{'mit Skill' if cond=='skill' else 'ohne Regelwerk':16}{len(mixed):3}/{len(c)} Tasks gemischt")
print("\n=== Kandidaten für Regelwerk-/Task-Mängel: mit Skill in beiden Modellen < 2 von 3 ===")
a,b=cells[('glm-5.3-flash','skill')],cells[('deepseek-v4.1-flash','skill')]
if a and b:
    bad=[(i,sum(r['ok'] for r in a[i]),sum(r['ok'] for r in b[i])) for i in a if i in b and sum(r['ok'] for r in a[i])<2 and sum(r['ok'] for r in b[i])<2]
    print(" ",[f"{i} (GLM {x}/3, Deepseek {y}/3)" for i,x,y in bad] or "keine")
print("\n=== Reines Vorwissen: Tasks, die ohne Regelwerk mindestens einmal bestehen (ohne Lecks) ===")
for m,_ in MODELS:
    c=cells[(m,'base')]
    if not c: continue
    ks=[(i,sum(r['ok'] and not r['leak'] for r in rs),len(rs)) for i,rs in c.items() if any(r['ok'] and not r['leak'] for r in rs)]
    print(f"  {m}: {len(ks)} Tasks:",[f"{i} {k}/{n}" for i,k,n in sorted(ks,key=lambda x:-x[1])][:25])
