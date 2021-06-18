import os
from Bio import SeqIO
import csv
import collections

catchments = [f"catchment_{i}" for i in range(1,config["catchment_count"]+1)]

rule all:
    input:
        expand(os.path.join(config["data_outdir"],"snipit","{catchment}.snipit.svg"), catchment=catchments),
        os.path.join(config["tempdir"],"snipit","prompt.txt")

rule make_snipit_alignments:
    input:
        fasta = config["fasta"],
        csv = config["csv"]
    output:
        expand(os.path.join(config["data_outdir"],"snipit","{catchment}.aln.fasta"), catchment=catchments)
    run:
        catchment_dict = collections.defaultdict(list)
        with open(input.csv,"r") as f:
            reader = csv.DictReader(f)
            
            if config["report_column"] in reader.fieldnames:
                column = config["report_column"]
            else:
                column = config["input_column"]

            for row in reader:
                if "query_boolean" in reader.fieldnames:
                    query = row["query_boolean"]
                
                if query=="True":
                    catchment_dict[row["catchment"]].append((row[column], row["hash"]))
        print(catchment_dict)
        sequences = {}
        for record in SeqIO.parse(input.fasta,"fasta"):
            sequences[record.id] = record

        for record in SeqIO.parse(config["outgroup_fasta"],"fasta"):
            reference = record
        
        for catchment in catchment_dict:
            with open(os.path.join(config["data_outdir"],"snipit",f"{catchment}.aln.fasta"),"w") as fw:
                records = [reference]

                for query in catchment_dict[catchment]:
                    print(query)
                    record = sequences[query[1]]
                    record.id = query[0]
                    records.append(record)

                SeqIO.write(records, fw, "fasta")

rule run_snipit:
    input:
        aln = os.path.join(config["data_outdir"],"snipit","{catchment}.aln.fasta")
    params:
        out_stem =os.path.join(config["data_outdir"],"snipit","{catchment}.snipit")
    output:
        os.path.join(config["data_outdir"],"snipit","{catchment}.snipit.svg")
    shell:
        """
        snipit {input.aln:q} -r "outgroup" -o {params.out_stem} -f svg
        """

rule gather_graphs:
    input:
        expand(os.path.join(config["data_outdir"],"snipit","{catchment}.snipit.svg"), catchment=catchments)
    output:
        os.path.join(config["tempdir"],"snipit","prompt.txt")
    shell:
        "touch {output:q}"
