
import csv
import sys
from civet.utils import misc
from civet.utils.log_colours import green,cyan,red


def parse_and_qc_table_cols(table_content, config):

    """ 
    parses the report group argument:
    --query-table-content (default --background_column,--background_date_column,source,lineage,country,catchment)
    """

    processed_columns = ["source","qc_status",config["input_display_column"],"catchment"]
    # processed_columns = ["source","qc_status","config["input_display_column"]","catchment","SNP_distance","closest","SNP_list"] #update when the analysis pipeline is done

    # if command line arg, overwrite config value
    misc.add_arg_to_config("query_table_content",table_content,config)

    if "input_metadata" in config:
        with open(config["input_metadata"]) as f:
            reader = csv.DictReader(f)
            input_fieldnames = reader.fieldnames
    else:
        input_fieldnames = []

    with open(config["background_metadata"]) as f:
        reader = csv.DictReader(f)
        background_fieldnames = reader.fieldnames

    if config["query_table_content"]:
        if type(config["query_table_content"]) == str:
            content_list = config["query_table_content"].split(",")
        else:
            content_list = config["query_table_content"]
        
        for col in content_list:
            if col not in processed_columns and col not in background_fieldnames and col not in input_fieldnames:
                sys.stderr.write(cyan(f"Error: {col} column not found in metadata file\n"))
                sys.exit(-1)
           
        if config["input_display_column"] not in content_list:
            content_list.insert(0,config["input_display_column"])

        config["query_table_content"] = content_list 
    else:
        sort_default_headers(input_fieldnames, background_fieldnames, config)

    config["fasta_table_content"] = [config["input_display_column"],"seq_N_content","seq_length"]


def sort_default_headers(input_fieldnames, background_fieldnames, config):

    basic_default_list = [config["input_display_column"], "lineage", "source", "catchment"]
    full_default_list = [config["background_date_column"], config["input_date_column"], "country", "adm1", "suggested_adm2_grouping", "adm2"]

    header_list = basic_default_list

    for col in full_default_list:
        if col: #deals with the date columns
            if col in (background_fieldnames or col in input_fieldnames) and col not in header_list: #so if eg the date columns are the same, they don't get added twice
                header_list.append(col)

    config["query_table_content"] = header_list


 