;寻址
;---
;立即数寻址
mov al, 5
mov ax, 3064h

;寄存器寻址
mov al, bh
mov ax, bx;mov cs, xx是错的

;有效地址(EA)寻址:  段寄存器:[基址(BX, BP)][变址(SI, DI)*比例因子][位移量]
;---
;直接寻址
mov bx, ds:[2100h];位移量是数字时,段寄存器不能省略
mov ax, es:[0300h]
mov ax, value;等价于mov ax, [value]; 其中value定义为: value dw 000ah, 执行后ax内为000ah(此条已写程序测试)
mov ax, word ptr [value];注意value应为word类型

;寄存器间接寻址
mov ax, [si];ax<-(ds*16+si)
mov ax, [di];ax<-(es*16+di)
mov ax, [bp];ax<-(ss*16+bp)
mov ax, [bx];ax<-(ds*16+bx)
;bp以外的约定段都是ds?和上面哪个对?
;在没有定义其它段的情况下,确实是ds;目前还不会定义其它段,以后再说

;寄存器相对寻址;在寄存器间接寻址上加了位移量
mov ax, value[bx];ax<-(ds:[bx+value])
;是否可用di?di约定段是es还是ds?value指的是value的值还是value的地址?
;可用di;目前是ds;value指的是地址,就很像c,数组名基本上就指数组首地址

;基址变址寻址;在寄存器间接寻址上加了基址
mov ax, [bx][si];等价于mov ax, [bx+si];ax<-(ds:[bx+si])
mov ax, [bp][di];ax<-(ss:[bp+di])
;段基地址由基址确定,是否可以更改?已建立jzbz.asm,有待验证

;相对基址变址寻址;在基址变址寻址上加了位移量
mov ax, value[bx][di];等价于value[bx+di], 等价于[bx+di+value]
mov ax, value[bp][si]
;二维数组

;跳转
;---
;段内直接寻址
jmp short skip;-128~127
nop
skip: jmp near ptr next;-32768~32767
nop
nop
next: nop
;条件转移指令只能用段内直接寻址

;段内间接寻址
;不能用立即数,其它寻址均可;把值直接赋给ip寄存器
jmp si
jmp word ptr value[bx]

;例子:
mov si, offset next;将next语句对应的ip值取出,送si
nop
next: nop

;段间直接寻址
jmp far ptr ano;ano为另一个代码段里的符号

;段间间接寻址;从内存中连续读2个字,地址小的放进ip,大的放进cs;寻址不能用立即数和寄存器(不够大),其他都行
jmp dword ptr [bx];dword双字, ds[bx]的字进了ip, ds[bx+2]的字进了cs

;数据传送
;---
;以下为mov的错误示范
;mov 0300h, ax;立即数不能为目标
;mov ds, 0300h;立即数不能直接给段寄存器
;mov cs, ax;不能用mov更改cs
;mov ds, es;两个操作数不能同时为段寄存器
;mov num[di], num[si];两个操作数不能同时为存储器(指令就超长了)
;mov不影响标志位

;堆栈
push ax
push dword ptr value
pop ax
;错误示范
;push al;pop al;至少是16位的字
;push 0300h;不能用立即数
;pop cs;不能手动改变cs
;不影响标志位

;交换
xchg al, bh
xchg bx, [bp][si]
xchg [bp][si], bx
;不影响标志位;不能使用段寄存器

;以下仅限ax用
in ax, 00h;长格式
in al, 0ffh;0-255;注意255必须用0ffh表示,因为要用数字打头才能是立即数
in ax, dx;大于255时只能先存到dx里
in al, dx

out 00h, ax
out 0ffh, al
out dx, ax

;换码指令
xlat;al<-(ds:[bx+al]);后可加变量名但没用,只相当于注释

;地址传送指令
lea si, value;取value的ea送给si
lea ax, [bx][si];取bx+si送给ax
lds si, value;si<-value, ds<-value+2
les di, value;同上,两个字,两个寄存器
lss sp, value
;目的不能是段寄存器,源必须为存储器寻址

;标志寄存器传送指令
lahf ;AH<-flag低8位
sahf;flag低8位<-AH
pushf;16bit的flags进栈
popf;从栈里读16位送进flags里

;类型转换
cbw;al符号扩展到ah
cwd;ax符号位到dx, dx:ax成双字

;算术指令
;---
;加减法均按照有符号数补码的规则计算, 影响of, sf, zf,af, pf, cf
add ax, bx;ax<- ax+bx
adc ax, bx;ax<- ax+bx+cf;带进位
inc si;si++

sub ax, bx;ax<- ax-bx
sbb ax, bx;ax<- ax-bx-cf;带进位
dec si;si--
neg ax;ax<- 256-ax
;neg有很多疑惑,值得写一个程序探究一下?
cmp ax, bx;ax-bx, 只影响标志位

;只改变cf和of:若高位为0则均为0,不为0则均为1
mul ch;ax=ch*al;操作数不能为立即数;无符号数乘法
mul cx; dx:ax=cx*ax
imul ch;ax=ch*al;有符号数乘法

;不改变flags,不能用立即数
div ch; al=ax/ch, ah=ax%ch
div cx; ax=dx:ax/cx, dx=dx:ax%cx
;idiv带符号数, 余数符号与被除数相同
idiv ch; al=ax/ch, ah=ax%ch
idiv cx; ax=dx:ax/cx, dx=dx:ax%cx
;除法溢出,程序直接中断

;压缩的bcd码调整
daa;调整al里的加法结果
das;调整al里的减法结果

;非压缩的bcd码调整(ascii)
aaa;加
aas;减
aam;乘
aad;除

;逻辑
and
or
not
xor
test

;移位指令
shl ax, cl;shift logical left, 逻辑左移
shl ax, 1;左移;1次的时候用立即数
sal al, cl;shift arithmetic left, 算数左移
shr dword ptr value, cl;shift logical right, 逻辑右移, 补0右移
sar;补符号位右移(算术右移)

;循环移位
rol;左移 rotate left
ror;右移 
rcl;带cf左移
rcr;带cf右移

;串处理指令
cld; df置零, si, di++
std; df置1, si, di--

rep xxx;重复执行xxx, 并cx--, 直到cx=0
repe/repz xxx;在rep基础上, 只有cmps或scas相等(zf=1)才重复
repne/repnz;不相等, 其余同上

movs es: byte ptr [di], [si]; 必须指明类型, 只能用es:[di]和es/ds:[si]; 执行时运输数据, 并根据df标志位自动加减di和si
movsb al, es:[si];寄存器只能用累加器(ax, al), 仅源串可以超越(ds改成es); 还有movsw

stos es: byte ptr [di]; 把al值给es:di, 只能是es:di, 需要指定类型
stosb/stosw [di]; 同上, [di]可写可不写?

lods es/ds: byte ptr [di]; 同上, 取出数据到al, ax中, 一般用于测试连续数据, 于是不和rep连用
lodsb/lodsw;同上

ins es: byte ptr [di], dx; 端口号要在dx,其余同上
insb/insw

outs dx, es/ds: byte ptr [di];同上, 端口号要在dx, 注意io速度
outsb/outsw

cmps es: byte ptr [di], es/ds: [si];同cmp与movs的规定;cmpsb;cmpsb
scas es/ds: byte ptr [di];与al, ax比较, al/ax - [di];scasb;scasw

;跳转
;---
;无条件
jmp label

;条件

;根据单个标志位
jz/je;zf=1, 为零
jnz/jne;zf=0
js;sf=1, 为负
jns;sf=0
jo;of=1, 有符号数溢出
jno;of=0
jp/jpe;pf=1, 偶数个1
jnp/jpo


;无符号数
jc/jb/jnae;cf=1, 低于/无符号数进位
jnc/jnb/jae
jbe/jna;低于等于
ja/jnbe;高于

;有符号数
jl/jnge;小于
jge/jnl;大于等于
jle/jng;小于等于
jg/jnle;大于

;用cx值
jcxz; cx为0则跳转, 只能short短转移

;循环
loop label;cx;只能short短转移
loope/loopz label
loopnz/loopne label

;子程序;注意堆栈
call
ret

;中断;注意堆栈;注意if
int n
iret

;标志位
cmc; cf取反
;clx;stx

;杂项
nop;空
hlt;停机, 直到外中断或reset
wait;等待, 直到test信号
lock;执行此语句期间锁定总线