function topo = buildTopology(layout)
%BUILDTOPOLOGY Build deterministic rectangular or staggered thermal graph.
if ~isfield(layout,'rows') || ~isfield(layout,'columns'), error('thermoweave:topology:Dimensions','rows and columns are required.'); end
nr = layout.rows; nc = layout.columns; N = nr*nc;
px=getField(layout,'pitchX_m',1); py=getField(layout,'pitchY_m',1);
type = lower(char(getField(layout,'type','rectangular')));
row = zeros(N,1); col=zeros(N,1); x=zeros(N,1); y=zeros(N,1);
for c=1:nc
    for r=1:nr
        i = r+(c-1)*nr; row(i)=r; col(i)=c;
        off = 0; if strcmp(type,'staggered') && mod(r,2)==0, off=0.5; end
        x(i)=((c-1)+off)*px; y(i)=(r-1)*py;
    end
end
edges=zeros(0,2); ge=zeros(0,1);
if strcmp(type,'rectangular')
    gx=getField(layout,'gx_W_per_K',getField(layout,'edgeConductance_W_per_K',1)); gy=getField(layout,'gy_W_per_K',gx);
    for i=1:N
        if col(i)<nc, edges(end+1,:)=[i i+nr]; ge(end+1,1)=gx; end %#ok<AGROW>
        if row(i)<nr, edges(end+1,:)=[i i+1]; ge(end+1,1)=gy; end %#ok<AGROW>
    end
else
    g0=getField(layout,'edgeConductance_W_per_K',1); tol=getField(layout,'neighborTolerance_m',1.25*max(px,py));
    for i=1:N
        for j=i+1:N
            dr=abs(y(i)-y(j)); dx=abs(x(i)-x(j)); d=hypot(dx,dr);
            sameRow = row(i)==row(j) && abs(col(i)-col(j))==1;
            adjacent = abs(row(i)-row(j))==1 && d<=tol;
            if sameRow || adjacent
                edges(end+1,:)=[i j]; ge(end+1,1)=g0*max(0.25,min(4,max(px,py)/max(d,eps))); %#ok<AGROW>
            end
        end
    end
end
if any(ge<=0), error('thermoweave:topology:Conductance','Edge conductances must be positive.'); end
zoneCount=getField(layout,'zoneCount',min(4,N)); zoneId=min(zoneCount,ceil((1:N)'/(N/zoneCount)));
B=zeros(size(edges,1),N); for e=1:size(edges,1),B(e,edges(e,1))=1;B(e,edges(e,2))=-1;end
topo=struct('nodeId',(1:N)','row',row,'column',col,'x_m',x,'y_m',y,'edges',edges, ...
    'edgeConductance_W_per_K',ge,'incidence',B,'laplacian_W_per_K',B'*diag(ge)*B,'zoneId',zoneId,'channelOrder',(1:N)', ...
    'nodeCount',N,'edgeCount',size(edges,1));
end
function v=getField(s,n,d),if isfield(s,n)&&~isempty(s.(n)),v=s.(n);else,v=d;end,end
