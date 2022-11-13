module cache(); 

parameter CACHE_SIZE=15;//in 2^CACHE_SIZE 
parameter ADDRESS_BITS =24;
parameter TOTAL_BITS=ADDRESS_BITS+4;
parameter WAYS=0;//2^WAYS 
parameter INDEX_BITS=CACHE_SIZE-OFFSET_BITS-WAYS;
parameter TAG_BITS=ADDRESS_BITS-INDEX_BITS-OFFSET_BITS ;
//parameter SETS=2**INDEX_BITS;
parameter OFFSET_BITS=6;
parameter INPUT_SIZE=524;
reg [(TOTAL_BITS-1):0]Address[(INPUT_SIZE-1):0];
reg [(TAG_BITS-1):0]tag_array[2**(INDEX_BITS)-1:0][2**(WAYS)-1:0];
reg valid[2**(INDEX_BITS)-1:0][2**(WAYS)-1:0];
reg dirty[2**(INDEX_BITS)-1:0][2**(WAYS)-1:0];
reg[(WAYS-1):0] lru[2**(INDEX_BITS)-1:0][2**(WAYS)-1:0];
integer ui,uj,k,i,j,index,tag,replace;
reg[39:0]HITS,MISSES,ReadHits,WriteHits,ReadMiss,WriteMiss;
reg hit; 
//inititalizing tag array and valid bits
initial begin
$readmemb("Addr_bin.txt",Address);  
HITS=0;hit=0;
ReadHits=0;WriteMiss=0;WriteHits=0;ReadMiss=0;
MISSES=0;
end
initial 
begin
    for(ui=0;ui<2**INDEX_BITS;ui=ui+1)begin
     for(uj=0;uj<2**WAYS;uj=uj+1) begin
        tag_array[ui][uj]=0;
        valid[ui][uj]=0;//set to 1 if valid
        dirty[ui][uj]=1;//set to zero if dirty
        lru[ui][uj]=2**WAYS-1;
     end 
    end 
    //iterating through the input
 for(i=0;i<INPUT_SIZE;i=i+1)begin
    hit=0;
    index=Address[i][(ADDRESS_BITS-TAG_BITS-1):(ADDRESS_BITS-TAG_BITS-INDEX_BITS)];
    tag=Address[i][(ADDRESS_BITS-1):(ADDRESS_BITS-TAG_BITS)];
    for(j=0;j<2**WAYS;j=j+1)begin
       
       if((valid[index][j])&&(tag==tag_array[index][j]))begin
        hit=1'b1;
        HITS=HITS+1;
        for(k=0;k<2**WAYS;k=k+1)begin
        if(lru[index][k]<lru[index][j]) begin
            lru[index][k]=lru[index][k]+1;
        end
        end
        lru[index][j]=0;
       end
    end
    if(Address[i][(TOTAL_BITS-1):(TOTAL_BITS-4)]==4'b10) //assuming 2 represents write operation
            dirty[index][k]=1'b0; //if write then it is set to zero indicating dirty for 
    if(hit==1'b1)begin
       if(Address[i][(TOTAL_BITS-1):(TOTAL_BITS-4)]==4'b1)
            ReadHits=ReadHits+1;
        else
            WriteHits=WriteHits+1;    
    end else begin //Miss
        replace=0;
        for(ui=0;ui<2**WAYS;ui=ui+1)begin
            if(lru[index][ui]>lru[index][replace])begin
            replace=ui; end
        end
        valid[index][replace]=1'b0;
        tag_array[index][replace]=tag;
        valid[index][replace]=1'b1;//on receiving block from memory
        for(j=0;j<2**WAYS;j=j+1)begin
            if(lru[index][j]<lru[index][replace])
                lru[index][j]=lru[index][j]+1;    
        end
        lru[index][replace]=0;
        dirty[index][replace]=1'b1;
        hit=1'b0;
        MISSES=MISSES+1;
       if(Address[i][(TOTAL_BITS-1):(TOTAL_BITS-4)]==4'b1)
            ReadMiss=ReadMiss+1;
        else
            WriteMiss=WriteMiss+1;  
    end
 end
$display("Hitrate ",(100*HITS)/INPUT_SIZE);
$display("The number of hits are: ",HITS,"\nThe number of misses are: ",MISSES);
$display("The Read hits are: ",ReadHits,"\nThe Read Misses are: ",ReadMiss);
$display("The Write hits are: ",WriteHits,"\nThe Write Misses are: ",WriteMiss);
end

endmodule
